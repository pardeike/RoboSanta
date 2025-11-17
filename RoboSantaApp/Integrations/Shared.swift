import Foundation
import Ollama

struct PromptTemplate {
    let system: String
    let scene: String

    func render(topicAction: String, topic: String) -> (system: String, user: String) {
        let user = """
        Scen: \(scene)
        Ämne att smyga in: \(topic)
        Krav: Svara endast med JSON som matchar schemat. En rad per fält.
        """
        return (system, user)
    }
}

struct GenerationOptions {
    var temperature: Double = 0.9
    var topP: Double = 0.95 // was 0.92
    var topK: Int = 50 // was 60
    var repeatPenalty: Double = 1.08 // was 1.1
    var seed: Int? = nil
    var stop: [String] = []
}

extension Property {
    func toSchema() -> Value {
        var map: [String: Value] = ["type": "string"]
        if let min = minLength { map["minLength"] = try! Value(Double(min)) }
        if let max = maxLength { map["maxLength"] = try! Value(Double(max)) }
        // single line; optionally discourage questions
        let basePattern = "^[^\\n]+$"
        let pattern = disallowQuestion ? "^(?!.*\\?).+$" : basePattern
        map["pattern"] = .string(pattern)
        map["description"] = .string(description)
        if !examples.isEmpty { map["examples"] = .array(examples.map(Value.string)) }
        return .object(map)
    }
}

extension Model {
    func toJSONSchema() -> Value {
        let props = Swift.Dictionary(uniqueKeysWithValues: properties.map { ($0.name, $0.toSchema()) })
        return [
            "type": "object",
            "additionalProperties": false,
            "required": .array(properties.map { .string($0.name) }),
            "properties": .object(props)
        ]
    }
}
