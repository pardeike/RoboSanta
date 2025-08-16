import AVFAudio

@MainActor
struct RoboSantaSpeaker: Speak {
    func say(_ text: String) async {
        
        let cleaned = text
            .replacingOccurrences(of: "Ho, ", with: "Ho ")
            .replacingOccurrences(of: "ho, ", with: "ho ")
        
        let process = Process()
        process.executableURL = Bundle.main.bundleURL.appending(components: "RoboSantaSpeaker")
        process.arguments = [cleaned]

        try? process.run()
        process.waitUntilExit()
    }
}
