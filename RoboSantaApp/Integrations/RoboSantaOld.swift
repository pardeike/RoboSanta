import AVFAudio
import AppKit

@MainActor
struct RoboSantaOld: SantaVoice {
    
    func list() {
        _ = AVSpeechSynthesisVoice.speechVoices().map { print($0) }
    }
    
    func loginShellEnvironment() -> [String:String] {
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
    
    func tts(_ label: String, _ text: String) async {
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: "/tmp/santa"), withIntermediateDirectories: true)
        let cleaned = text.cleanup()
        print("🗣️ \(label): \(cleaned) ", terminator: "")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3.11")
        process.arguments = ["/Users/u0035718/Scripts/santa.py", "/tmp/santa/\(label).wav", cleaned]

        var env = loginShellEnvironment()
        env["PATH"] = (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin") + ":/opt/homebrew/bin"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        process.environment = env

        let err = Pipe(); process.standardError = err
        let out = Pipe(); process.standardOutput = out

        try? process.run()
        process.waitUntilExit()

        if let s = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), !s.isEmpty {
            print("python stderr:", s)
        }
        
        print("✓")
    }
    
    func speak() async {
    }
    
    func speak(_ labels: [String]) async {
        print("🔊 ", terminator: "")
        for label in labels {
            if let ms = Int(label.replacingOccurrences(of: "WAIT", with: "")), ms > 0 {
                try? await Task.sleep(for: .milliseconds(ms))
                continue
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
            process.arguments = ["/tmp/santa/\(label).wav"]
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to run afplay: \(error)")
            }
            print(".", terminator: "")
        }
        print("✓")
    }
    
    /*func say(_ label: String, _ text: String) async {
        let cleaned = text.cleanup()
        print("\(label): \(cleaned)")
        try? cleaned.write(toFile: "/tmp/say.txt", atomically: false, encoding: .utf8)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-f", "/tmp/say.txt"]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run say: \(error)")
        }
    }*/
}
