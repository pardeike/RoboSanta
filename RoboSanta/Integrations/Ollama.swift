import Foundation
import Ollama
import FoundationModels

@MainActor
struct Ollama: Think {
    
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
    
    func convertSchema(_ schema: [String: JSONValue]) -> Value {
        var result = [String : Value]()
        for field in schema {
            result[field.key] = convert(field.value)
        }
        return .object(result)
    }
    
    func convert(_ value: JSONValue) -> Value {
        switch value {
        case .array(let val):
            return .array(val.map({ convert($0) }))
        case .bool(let val):
            return .bool(val)
        case .number(let val):
            return .double(val)
        case .object(let val):
            var res = [String: Value]()
            for (k, v) in val { res[k] = convert(v) }
            return .object(res)
        case .string(let val):
            return .string(val)
        default:
            return .null
        }
    }
    
    func generateText(_ prompt: String, _ model: Model) async -> Answer? {
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
            let client = await Client(host: URL(string: "http://localhost:11434")!)
            print("Ollama... ", terminator: "")
            let start = Date().timeIntervalSince1970
            let json = try await client.chat(
                model: "gemma3n",
                messages: [
                    .system(model.description),
                    .user(prompt)
                ],
                format: convertSchema(schema)
            ).message.content
            print("\(Int(Date().timeIntervalSince1970 - start))s")
            let content = try FoundationModels.GeneratedContent.init(json: json)
            return Answer(model: model, content: content)
        } catch {
            print(error)
            return nil
        }
    }
}
