import Foundation

struct TTSServer {
    
    static let tempSantaDir = URL(fileURLWithPath: "/tmp/santa")
    static var files: [String] = []
    
    init() {
        let scriptDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RoboSantaApp/Integrations
            .deletingLastPathComponent() // RoboSantaApp
            .deletingLastPathComponent() // Repo root
        let scriptURL = scriptDirectory.appendingPathComponent("tts-server.py")
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            print("tts-server.py not found at \(scriptURL.path)")
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python")
        process.arguments = ["tts-server.py"]
        process.currentDirectoryURL = scriptDirectory
        try! process.run()
    }
}
