import Foundation
import Dispatch

class TTSServer {
    
    var files: [String] = []
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let outputQueue = DispatchQueue(label: "TTSServer.OutputQueue")
    private var stdoutBuffer = Data()
    private var isServerReady = false
    private let readinessMarker = Data("TTS server listening on".utf8)
    private let readySemaphore = DispatchSemaphore(value: 0)
    private var readinessTask: Task<Void, Never>?
    
    init() {
        readinessTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            self.waitForServerReady()
        }
        
        print("Starting tts-server...")
        
        if checkExistingServer() {
            print("Reusing existing tts-server.")
            return
        }
        
        let scriptDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RoboSantaApp/Integrations
            .deletingLastPathComponent() // RoboSantaApp
        let scriptURL = scriptDirectory.appendingPathComponent("tts-server.py")
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            print("tts-server.py not found at \(scriptURL.path)")
            readySemaphore.signal()
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
            self.readySemaphore.signal()
            self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
            self.stderrPipe?.fileHandleForReading.readabilityHandler = nil
        }
        
        do {
            try process.run()
            self.process = process
        } catch {
            print("Failed to start tts-server: \(error)")
            readySemaphore.signal()
        }
    }
    
    private func checkExistingServer() -> Bool {
        guard isServerReachable() else { return false }
        markServerReady()
        return true
    }
    
    func waitUntilReady() async -> Bool {
        if outputQueue.sync(execute: { isServerReady }) {
            return true
        }
        guard let readinessTask else { return false }
        await readinessTask.value
        return outputQueue.sync { isServerReady }
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
        var shouldSignal = false
        outputQueue.sync {
            if !isServerReady {
                isServerReady = true
                shouldSignal = true
            }
        }
        if shouldSignal {
            readySemaphore.signal()
        }
    }
    
    private func waitForServerReady(timeout: TimeInterval = 120) {
        let result = readySemaphore.wait(timeout: .now() + timeout)
        switch result {
        case .success where isServerReady:
            print("tts-server is ready.")
        case .success:
            print("tts-server exited before it became ready.")
        case .timedOut:
            print("Timed out waiting for tts-server to start.")
        }
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
