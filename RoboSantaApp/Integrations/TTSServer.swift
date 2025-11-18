import Foundation

class TTSServer {
    
    var files: [String] = []
    
    init() {
        let scriptDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RoboSantaApp/Integrations
            .deletingLastPathComponent() // RoboSantaApp
        let scriptURL = scriptDirectory.appendingPathComponent("tts-server.py")
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            print("tts-server.py not found at \(scriptURL.path)")
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
        
        print("Starting tts-server...")
        
        let err = Pipe(); process.standardError = err
        let out = Pipe(); process.standardOutput = out
        try? process.run()
        process.waitUntilExit()

        if let s = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), !s.isEmpty {
            print("The tts-server ended with error: ", s)
        } else {
            print("The tts-server has ended.")
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
