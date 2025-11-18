import Foundation
import Ollama
import FoundationModels

@MainActor
struct OllamaThink: Think {
    let modelName: Ollama.Model.ID
    let client: Client = .default

    func generate<T: Decodable>(template: PromptTemplate, topicAction: String, topic: String, model: Model, options: GenerationOptions) async throws -> T {
        
        let (system, user) = template.render(topicAction: topicAction, topic: topic)
        let schema = model.toJSONSchema()
        
        // map provider-agnostic options to Ollama's snake_case fields
        var opts: [String: Value] = [
            "temperature": try! Value(options.temperature),
            "top_p": try! Value(options.topP),
            "top_k": try! Value(options.topK),
            "repeat_penalty": try! Value(options.repeatPenalty),
        ]
        if let seed = options.seed { opts["seed"] = try! Value(seed) }
        if !options.stop.isEmpty { opts["stop"] = try! Value(options.stop) }
        
        print("Sending...")
        
        var resp: Client.ChatResponse?
        while true {
            do {
                resp = try await client.chat(
                    model: modelName,
                    messages: [
                        .system(system),
                        .user(user)
                    ],
                    options: opts,
                    format: schema,
                    think: true,
                )
                break
            } catch {
                if let urlError = error as? URLError, urlError.errorCode == -1005 {
                    print("Retrying...")
                } else {
                    break
                }
            }
        }
        
        guard let resp else { return try JSONDecoder().decode(T.self, from: Data()) }
        
        //print("Thinking: \(resp.message.thinking ?? "")")
        //print("Content: \(resp.message.content)")
        
        let content = try FoundationModels.GeneratedContent(json: resp.message.content)
        if content.jsonString == "" { print("Unexpected empty result from Ollama") }
        return try JSONDecoder().decode(T.self, from: content.jsonString.data(using: .utf8) ?? Data())
    }
}
