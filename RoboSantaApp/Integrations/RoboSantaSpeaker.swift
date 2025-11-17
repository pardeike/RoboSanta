import AVFAudio
import AppKit

@MainActor
struct RoboSantaSpeaker: Speak {
    
    func list() {
        _ = AVSpeechSynthesisVoice.speechVoices().map { print($0) }
    }
    
    func say(_ label: String, _ text: String) async {
        let cleaned = text.removingEmojis().trimmingCharacters(in: .whitespacesAndNewlines)
        print("\(label): \(cleaned)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = [text]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run say: \(error)")
        }
    }
}
