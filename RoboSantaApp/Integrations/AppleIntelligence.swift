import FoundationModels
import Foundation

@MainActor
struct AppleIntelligence: Think {
    func generateText(_ prompt: String, _ model: Model) async -> Answer? {
        while true {
            do {
                let session = LanguageModelSession(instructions: "The current time is <TIME>. You are best at coming up with short Swedish phrases that are funny and have a good punchline.".replacingOccurrences(of: "<TIME>", with: fuzzyEnglishTime()))
                let schema = try model.dynamicGenerationSchema()
                let content = try await session.respond(to: prompt, schema: schema, includeSchemaInPrompt: true).content
                var bad = ""
                for field in model.properties.map({ $0.name }) {
                    let value = try? content.value(String.self, forProperty: field)
                    if let value {
                        if value.isEmpty {
                            bad = "field empty"
                        } else {
                            if value.contains(/[\n%&‰]/) {
                                bad = "bad characters"
                            }
                        }
                    } else {
                        bad = "field missing"
                    }
                }
                if bad != "" {
                    print("Retrying due to \(bad)")
                    continue
                }
                return Answer(model: model, content: content)
            } catch {
                if error is LanguageModelSession.GenerationError {
                    print("Retrying due to error")
                    continue
                }
                print("Error: \(error)")
            }
        }
    }
}
