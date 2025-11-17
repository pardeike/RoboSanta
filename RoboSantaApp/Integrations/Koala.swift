import Foundation
import FoundationModels

@MainActor
struct Koala: Think {
    let modelName: String
    let baseURL: String
    let apiKey: String

    init(modelName: String = "/model/koala-v2",
         baseURL: String = "https://koala-api01.polisen.se/v1",
         apiKey: String = "none") {
        self.modelName = modelName
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    func generate<T: Decodable>(template: PromptTemplate, topicAction: String, topic: String, model: Model, options: GenerationOptions) async throws -> T {

        let (system, user) = template.render(topicAction: topicAction, topic: topic)
        let schema = buildJSONSchema(from: model)

        do {
            return try await callJSONSchema(system: system, user: user,
                                            schema: schema, options: options)
        } catch {
            // fallback to function-calling tools (widely supported by OpenAI-compatible servers)
            return try await callTools(system: system, user: user,
                                       schema: schema, modelNameForTool: model.name,
                                       options: options)
        }
    }

    private func callJSONSchema<T: Decodable>(
        system: String,
        user: String,
        schema: [String: Any],
        options: GenerationOptions
    ) async throws -> T {

        var body: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": options.temperature,
            "top_p": options.topP,
        ]

        body["response_format"] = [
            "type": "json_schema",
            "json_schema": [
                "name": "RoboSanta",
                "schema": schema,
                "strict": true
            ]
        ]

        mapPenalties(into: &body, from: options)
        if let seed = options.seed { body["seed"] = seed }
        if !options.stop.isEmpty { body["stop"] = options.stop }

        let json = try await post(path: "/chat/completions", body: body)
        guard
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw KoalaError.invalidResponseFormat }

        let cleaned = stripCodeFences(content)
        guard let data = cleaned.data(using: .utf8) else { throw KoalaError.invalidContentEncoding }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func callTools<T: Decodable>(
        system: String,
        user: String,
        schema: [String: Any],
        modelNameForTool: String,
        options: GenerationOptions
    ) async throws -> T {

        var body: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": options.temperature,
            "top_p": options.topP,
        ]

        body["tools"] = [[
            "type": "function",
            "function": [
                "name": modelNameForTool,
                "description": "Return exactly these fields.",
                "parameters": schema
            ]
        ]]

        body["tool_choice"] = [
            "type": "function",
            "function": ["name": modelNameForTool]
        ]

        mapPenalties(into: &body, from: options)
        if let seed = options.seed { body["seed"] = seed }
        if !options.stop.isEmpty { body["stop"] = options.stop }

        let json = try await post(path: "/chat/completions", body: body)

        guard
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any]
        else { throw KoalaError.invalidResponseFormat }

        if let toolCalls = message["tool_calls"] as? [[String: Any]],
           let first = toolCalls.first,
           let function = first["function"] as? [String: Any],
           let args = function["arguments"] as? String {
            let data = Data(args.utf8)
            return try JSONDecoder().decode(T.self, from: data)
        }

        if let content = message["content"] as? String {
            let cleaned = stripCodeFences(content)
            let data = Data(cleaned.utf8)
            return try JSONDecoder().decode(T.self, from: data)
        }

        throw KoalaError.invalidResponseFormat
    }

    private func buildJSONSchema(from model: Model) -> [String: Any] {
        var properties: [String: Any] = [:]
        var required: [String] = []

        for p in model.properties {
            required.append(p.name)
            var prop: [String: Any] = [
                "type": "string",
                "description": p.description
            ]
            // Optional: add soft length/line constraints to curb verbosity
            prop["maxLength"] = 120
            prop["pattern"] = #"^[^\n]+$"#
            properties[p.name] = prop
        }

        return [
            "type": "object",
            "additionalProperties": false,
            "properties": properties,
            "required": required
        ]
    }

    private func mapPenalties(into body: inout [String: Any], from opts: GenerationOptions) {
        if opts.repeatPenalty != 1.0 {
            // heuristic mapping: repeatPenalty > 1 → modest frequency/presence penalties
            let penalty = max(0, min(2, (opts.repeatPenalty - 1.0) * 2.0))
            body["frequency_penalty"] = penalty
            body["presence_penalty"]  = penalty * 0.5
        }
    }

    private func stripCodeFences(_ s: String) -> String {
        s.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func post(path: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw KoalaError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if apiKey.lowercased() != "none" {
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw KoalaError.apiError((resp as? HTTPURLResponse)?.statusCode ?? -1, text)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw KoalaError.invalidResponseFormat
        }
        return json
    }
}


enum KoalaError: Error, LocalizedError {
    case invalidURL
    case requestSerializationFailed(Error)
    case apiError(Int, String)
    case invalidResponseFormat
    case invalidContentEncoding
    case decodingFailed(Error)
    case responseParsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for API"
        case .requestSerializationFailed(let error):
            return "Failed to serialize request: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .invalidResponseFormat:
            return "Invalid response format from API"
        case .invalidContentEncoding:
            return "Failed to encode response content"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .responseParsingFailed(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
