import FoundationModels
import Foundation

@MainActor
struct AppleIntelligence: Think {
    func generate<T: Decodable>(template: PromptTemplate, topicAction: String, topic: String, model: Model, options: GenerationOptions) async throws -> T {
        guard SystemLanguageModel.default.isAvailable else {
            fatalError("No system model available")
        }
        while true {
            do {
                let (system, user) = template.render(topicAction: topicAction, topic: topic)
                let schema: GenerationSchema = try model.dynamicGenerationSchema()
                let session = LanguageModelSession(instructions: system)
                let response = try await session.respond(to: user, schema: schema, options: FoundationModels.GenerationOptions(temperature: options.temperature)).content
                return try JSONDecoder().decode(T.self, from: response.generatedContent.jsonString.data(using: .utf8) ?? Data())
            } catch {
                //if error is LanguageModelSession.GenerationError {
                //    print("Retrying due to error")
                //    continue
                //}
                print("Error: \(error)")
            }
        }
    }
}
