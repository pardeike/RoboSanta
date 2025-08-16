import FoundationModels
import Foundation

@MainActor
struct AppleIntelligence: Think {
    func generateText(_ prompt: String) async -> String? {
        let session = LanguageModelSession(instructions: "You are best on coming up with short Swedish phrases that are funny and have a good punchline.")
        var text = "God Jul!"
        while true {
            do {
                let response = try await session.respond(to: prompt).content
                let lines = response.split(separator: "\n").map { String($0) }
                text = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
                if text.contains("1.") { continue }
            } catch {
                if let generationError = error as? LanguageModelSession.GenerationError {
                    print("Retrying due to generation error: \(generationError.failureReason ?? "-")")
                    continue
                }
                print("Error: \(error)")
            }
            break
        }
        let parts = text.split(separator: ":")
        if parts.count > 1 { text = String(parts[1]) }
        return text.replacingOccurrences(of: "\"", with: "")
    }
}
