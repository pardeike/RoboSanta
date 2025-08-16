import Foundation

@MainActor
struct OpenAI: Think {
    struct Input: Encodable {
        let model: String
        let input: String
    }
    
    struct Content: Codable {
        let text: String
    }

    struct OutputItem: Codable {
        let type: String
        let content: [Content]?
        let role: String?
    }

    struct Output: Codable {
        let output: [OutputItem]
    }
    
    func generateText(_ prompt: String) async -> String? {
        let model = "gpt-4.1-nano" // "gpt-4-turbo"
        guard let apiKey = getAPIKey("RoboSanta OpenAI API Key"), !apiKey.isEmpty else {
            print("Missing OpenAI API key")
            return nil
        }
        do {
            let url = "https://api.openai.com/v1/responses"
            var req = URLRequest(url: URL(string: url)!)
            req.httpMethod = "POST"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(Input(
                model: model,
                input: prompt
            ))
            guard let (data, response) = try? await URLSession.shared.data(for: req) else { return nil }
            guard let urlResponse = response as? HTTPURLResponse else { return nil }
            guard urlResponse.statusCode == 200 else { return nil }
            // print("Response: \(String(data: data, encoding: .utf8) ?? "")")
            guard let result = try? JSONDecoder().decode(Output.self, from: data) else { return nil }
            return result.output.first { $0.role == "assistant" }?.content?[0].text
        } catch {
            print(error)
            return nil
        }
    }
}
