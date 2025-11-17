import Foundation
import FoundationModels

@MainActor
struct OpenAI: Think {
    
    var modelName = "o4-mini"
    
    struct TextFormat: Encodable {
        let type = "json_schema"
        let name = "RoboSanta"
        let schema: [String: JSONValue]
        let strict = true
    }

    struct TextInfo: Encodable {
        let format: TextFormat
    }
    
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Input: Encodable {
        let model: String
        let input: [Message]
        let text: TextInfo
        let service_tier = "flex"
    }
    
    struct Content: Decodable {
        let text: String
    }

    struct OutputItem: Decodable {
        let type: String
        let content: [Content]?
        let role: String?
    }
    
    struct Usage: Decodable {
        let input_tokens: Int
        let output_tokens: Int
        let total_tokens: Int
    }

    struct Output: Decodable {
        let output: [OutputItem]
        let usage: Usage
    }
    
    func kronor(_ usage: OpenAI.Usage) -> Double {
        (
            Double(usage.input_tokens) / 1_000_000.0 * 0.025
            +
            Double(usage.output_tokens) / 1_000_000.0 * 0.20
        )
        *
        9.35852
    }
    
    func generateText(_ prompt: String, _ topicAction: String, _ topic: String, _ model: Model) async -> Answer? {
        guard let apiKey = getAPIKey("RoboSanta OpenAI API Key"), !apiKey.isEmpty else {
            print("Missing OpenAI API key")
            return nil
        }
        
        let propertyNames = model.properties.map { JSONValue.string($0.name) }
        var properties: [String: JSONValue] = [:]
        for p in model.properties {
            properties[p.name] = .object([
                "type": .string("string"),
                "description": .string(p.description),
            ])
        }
        let schema: [String: JSONValue] = [
            "type": .string("object"),
            "properties": .object(properties),
            "required": .array(propertyNames),
            "additionalProperties": .bool(false)
        ]
        
        do {
            let url = "https://api.openai.com/v1/responses"
            var req = URLRequest(url: URL(string: url)!)
            req.httpMethod = "POST"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(Input(
                model: modelName,
                input: [
                    Message(role: "system", content: model.description),
                    Message(role: "user", content: prompt.makeRandom(topicAction, topic))
                ],
                text: TextInfo(format: TextFormat(schema: schema))
            ))
            print("OpenAI (\(topic))... ", terminator: "")
            let start = Date().timeIntervalSince1970
            guard let (data, response) = try? await URLSession.shared.data(for: req) else { return nil }
            guard let urlResponse = response as? HTTPURLResponse else { return nil }
            guard urlResponse.statusCode == 200 else { return nil }
            guard let result = try? JSONDecoder().decode(Output.self, from: data) else { return nil }
            print("\(Int(Date().timeIntervalSince1970 - start))s \(result.usage.input_tokens)->\(result.usage.output_tokens) (\(kronor(result.usage)) SEK)")
            guard let json = result.output.first(where: { $0.role == "assistant" })?.content?[0].text else { return nil }
            let content = try FoundationModels.GeneratedContent.init(json: json)
            return Answer(model: model, content: content)
        } catch {
            print(error)
            return nil
        }
    }
}
