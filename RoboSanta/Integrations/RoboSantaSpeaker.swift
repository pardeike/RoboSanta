import AVFAudio

@MainActor
struct RoboSantaSpeaker: Speak {
    func say(_ label: String, _ text: String) async {
        let cleaned = text.removingEmojis().trimmingCharacters(in: .whitespacesAndNewlines)
        print("\(label): \(cleaned)")
        
        let process = Process()
        process.executableURL = Bundle.main.bundleURL.appending(components: "RoboSantaSpeaker")
        process.arguments = [cleaned]

        try? process.run()
        process.waitUntilExit()
    }
}
