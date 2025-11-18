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
    
    init() {
        if checkExistingServer() {
            print("Reusing existing tts-server.")
            return
        }
        
        let scriptDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RoboSantaApp/Integrations
            .deletingLastPathComponent() // RoboSantaApp
        let scriptURL = scriptDirectory.appendingPathComponent("tts-server.py")
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            completeReadiness(success: false, message: "tts-server.py not found at \(scriptURL.path)")
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python")
        process.arguments = ["tts-server.py"]
        process.currentDirectoryURL = scriptDirectory
        
        var env = loginShellEnvironment()
        env["PATH"] = (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin") + ":/opt/homebrew/bin"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        process.environment = env
        
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
            scheduleReadinessTimeout()
        } catch {
            print("Failed to start tts-server: \(error)")
            completeReadiness(success: false, message: "Failed to start tts-server.")
        }
    }
    
    private func checkExistingServer() -> Bool {
        guard isServerReachable() else { return false }
        markServerReady()
        return true
    }
    
    func waitUntilReady() async -> Bool {
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
        guard let url = URL(string: "http://127.0.0.1:8080/") else { return false }
        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        
        let task = session.dataTask(with: url) { _, response, error in
            if error == nil, let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
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
}
