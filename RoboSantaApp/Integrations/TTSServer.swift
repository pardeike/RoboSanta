import Foundation
import Dispatch

class TTSServer {
    
    var files: [String] = []
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private enum ReadinessState {
        case pending
        case ready
        case failed
    }
    private let outputQueue = DispatchQueue(label: "TTSServer.OutputQueue")
    private var stdoutBuffer = Data()
    private var isServerReady = false
    private let readinessMarker = Data("TTS server listening on".utf8)
    private var readinessContinuations: [CheckedContinuation<Bool, Never>] = []
    private var readinessState: ReadinessState = .pending
    private var readinessTimeoutTask: Task<Void, Never>?
    private let readinessTimeout: TimeInterval = 120
    private let restartInterval: TimeInterval = 3600 // Periodically purge Python memory use
    private var lastLaunchDate = Date()
    private var isRestarting = false
    private var suppressTerminationHandler = false
    
    init() {
        startServer()
    }
    
    private func startServer() {
        if checkExistingServer() {
            print("Reusing existing tts-server.")
            lastLaunchDate = Date()
            return
        }
        launchNewProcess()
    }
    
    private func launchNewProcess() {
        resetReadinessTracking()
        
        let scriptDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RoboSantaApp/Integrations
            .deletingLastPathComponent() // RoboSantaApp
        let scriptURL = scriptDirectory.appendingPathComponent("tts-server.py")
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            completeReadiness(success: false, message: "tts-server.py not found at \(scriptURL.path)")
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3.11")
        process.arguments = ["tts-server.py"]
        process.currentDirectoryURL = scriptDirectory
        
        process.environment = sanitizedEnvironment()
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
        
        attachOutputHandler(pipe: stdoutPipe, isError: false, monitorsReadiness: true)
        attachOutputHandler(pipe: stderrPipe, isError: true, monitorsReadiness: false)
        
        process.terminationHandler = { [weak self] proc in
            guard let self else { return }
            if self.suppressTerminationHandler {
                return
            }
            if proc.terminationStatus != 0 {
                print("tts-server exited with status \(proc.terminationStatus)")
            }
            self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
            self.stderrPipe?.fileHandleForReading.readabilityHandler = nil
            let wasReady = self.outputQueue.sync { self.isServerReady }
            if !wasReady {
                self.completeReadiness(success: false, message: "tts-server exited before it became ready.")
            }
        }
        
        do {
            try process.run()
            self.process = process
            lastLaunchDate = Date()
            scheduleReadinessTimeout()
        } catch {
            print("Failed to start tts-server: \(error)")
            completeReadiness(success: false, message: "Failed to start tts-server.")
        }
    }
    
    private func resetReadinessTracking() {
        readinessTimeoutTask?.cancel()
        readinessTimeoutTask = nil
        outputQueue.sync {
            stdoutBuffer.removeAll()
            isServerReady = false
            readinessState = .pending
            readinessContinuations.removeAll()
        }
    }
    
    private func shutdownProcess() async {
        guard let proc = process else { return }
        proc.terminationHandler = nil
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        proc.terminate()
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                proc.waitUntilExit()
                continuation.resume()
            }
        }
        
        process = nil
        stdoutPipe = nil
        stderrPipe = nil
    }
    
    private func restartServer(reason: String) async -> Bool {
        if isRestarting {
            return await awaitReadiness()
        }
        
        isRestarting = true
        suppressTerminationHandler = true
        print("Restarting tts-server (\(reason)).")
        await shutdownProcess()
        suppressTerminationHandler = false
        launchNewProcess()
        let ready = await awaitReadiness()
        isRestarting = false
        return ready
    }
    
    private func shouldRestartForAge() -> Bool {
        guard let proc = process, proc.isRunning else { return false }
        let uptime = Date().timeIntervalSince(lastLaunchDate)
        return uptime >= restartInterval
    }
    
    private func checkExistingServer() -> Bool {
        guard isServerReachable() else { return false }
        markServerReady()
        return true
    }
    
    func waitUntilReady() async -> Bool {
        let state = outputQueue.sync { readinessState }
        
        // Recover from failed launches so we do not get stuck forever.
        if state == .failed {
            return await restartServer(reason: "previous start failed or server stopped")
        }
        
        // If a launch is already in progress, keep waiting unless the process died.
        if state == .pending {
            let running = process?.isRunning ?? false
            if !running && !isServerReachable() {
                return await restartServer(reason: "server stopped during startup")
            }
            return await awaitReadiness()
        }
        
        // At this point we believe the server is ready; verify liveness and age.
        if !isServerReachable() {
            return await restartServer(reason: "server unreachable")
        }
        
        if shouldRestartForAge() {
            let uptime = Int(Date().timeIntervalSince(lastLaunchDate))
            return await restartServer(reason: "periodic purge after \(uptime)s")
        }
        
        return true
    }
    
    private func awaitReadiness() async -> Bool {
        let state = outputQueue.sync { readinessState }
        switch state {
        case .ready:
            return true
        case .failed:
            return false
        case .pending:
            return await withCheckedContinuation { continuation in
                outputQueue.async {
                    switch self.readinessState {
                    case .ready:
                        continuation.resume(returning: true)
                    case .failed:
                        continuation.resume(returning: false)
                    case .pending:
                        self.readinessContinuations.append(continuation)
                    }
                }
            }
        }
    }
    
    private func scheduleReadinessTimeout() {
        readinessTimeoutTask?.cancel()
        readinessTimeoutTask = Task { [weak self] in
            guard let self else { return }
            let nanoseconds = UInt64(max(0, readinessTimeout) * 1_000_000_000)
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            self.completeReadiness(success: false, message: "Timed out waiting for tts-server to start.")
        }
    }
    
    private func completeReadiness(success: Bool, message: String) {
        var continuations: [CheckedContinuation<Bool, Never>] = []
        var shouldNotify = false
        outputQueue.sync {
            guard readinessState == .pending else { return }
            readinessState = success ? .ready : .failed
            if success {
                isServerReady = true
            }
            continuations = readinessContinuations
            readinessContinuations.removeAll()
            shouldNotify = true
        }
        guard shouldNotify else { return }
        readinessTimeoutTask?.cancel()
        readinessTimeoutTask = nil
        // print(message)
        continuations.forEach { $0.resume(returning: success) }
    }
    
    private func isServerReachable(timeout: TimeInterval = 2) -> Bool {
        guard let url = URL(string: "http://127.0.0.1:8080/healthz") else { return false }
        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        
        let task = session.dataTask(with: url) { _, response, error in
            // Server is reachable if we get any HTTP response (including 404)
            if error == nil, response is HTTPURLResponse {
                reachable = true
            }
            semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .now() + timeout)
        return reachable
    }
    
    private func attachOutputHandler(pipe: Pipe, isError: Bool, monitorsReadiness: Bool) {
        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] fileHandle in
            guard let self else { return }
            let data = fileHandle.availableData
            guard !data.isEmpty else {
                fileHandle.readabilityHandler = nil
                return
            }
            self.forward(data: data, isError: isError)
            if monitorsReadiness {
                self.processStdoutChunk(data: data)
            }
        }
    }
    
    private func forward(data: Data, isError: Bool) {
        if isError {
            FileHandle.standardError.write(data)
        } else {
            FileHandle.standardOutput.write(data)
        }
    }
    
    private func processStdoutChunk(data: Data) {
        var shouldMarkReady = false
        outputQueue.sync {
            guard !isServerReady else { return }
            stdoutBuffer.append(data)
            if stdoutBuffer.count > 8192 {
                stdoutBuffer.removeFirst(stdoutBuffer.count - 8192)
            }
            if stdoutBuffer.range(of: readinessMarker) != nil {
                shouldMarkReady = true
            }
        }
        if shouldMarkReady {
            markServerReady()
        }
    }
    
    private func markServerReady() {
        completeReadiness(success: true, message: "tts-server is ready.")
    }
    
    private func loginShellEnvironment() -> [String:String] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        p.arguments = ["-lc", "source ~/.zprofile 2>/dev/null; source ~/.zshrc 2>/dev/null; /usr/bin/env"]
        let out = Pipe()
        p.standardOutput = out
        try? p.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return [:] }

        var env: [String:String] = [:]
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if let eq = line.firstIndex(of: "=") {
                let key = String(line[..<eq])
                let value = String(line[line.index(after: eq)...])
                env[key] = value
            }
        }
        return env
    }

    private func sanitizedEnvironment() -> [String:String] {
        var env = loginShellEnvironment()
        env["PATH"] = (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin") + ":/opt/homebrew/bin"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        env["PYTHONUNBUFFERED"] = "1"

        // Avoid inheriting corporate proxy settings that break local TTS startup.
        for key in ["HTTP_PROXY", "http_proxy", "HTTPS_PROXY", "https_proxy", "ALL_PROXY", "all_proxy"] {
            env.removeValue(forKey: key)
        }
        env["NO_PROXY"] = "127.0.0.1,localhost"
        env["no_proxy"] = "127.0.0.1,localhost"

        // Force offline mode so HuggingFace never tries to reach the network when loading cached models.
        env["HF_HUB_OFFLINE"] = env["HF_HUB_OFFLINE"] ?? "1"
        env["TRANSFORMERS_OFFLINE"] = env["TRANSFORMERS_OFFLINE"] ?? "1"
        env["HF_HUB_DISABLE_TELEMETRY"] = env["HF_HUB_DISABLE_TELEMETRY"] ?? "1"
        return env
    }
}
