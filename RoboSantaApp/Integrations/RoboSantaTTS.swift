import AVFAudio
import Foundation

@MainActor
struct RoboSantaTTS: SantaVoice {
    let server = TTSServer()

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        session = URLSession(configuration: configuration)
    }

    func tts(_ file: String, _ text: String) async {
        let cleaned = text.cleanup()
        guard !cleaned.isEmpty else { return }
        print("\(file): \(cleaned)")
        guard await server.waitUntilReady() else {
            print("TTS server not ready for \(file)")
            return
        }

        struct Payload: Encodable {
            let voice: String
            let text: String
        }

        struct Response: Decodable {
            let uuid: String
        }

        // Step 1: Send POST request to generate TTS (without file parameter)
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8080")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = Payload(voice: "alfons1", text: cleaned)
        request.httpBody = try? JSONEncoder().encode(payload)
        request.timeoutInterval = 300

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid TTS server response for \(file)")
                return
            }
            guard httpResponse.statusCode == 200 else {
                print("TTS server responded with status \(httpResponse.statusCode) for \(file)")
                return
            }
            
            // Parse UUID from response
            let responseData = try JSONDecoder().decode(Response.self, from: data)
            let uuid = responseData.uuid
            print("Generated TTS file with UUID: \(uuid)")
            
            // Step 2: Store UUID for later playback
            server.files.append(uuid)
        } catch {
            print("TTS request failed for \(file): \(error)")
        }
    }

    func speak() async {
        for file in server.files {
            if file.starts(with: "#") {
                let ms = Int(String(file.dropFirst()))!
                try? await Task.sleep(for: .milliseconds(ms))
                continue
            }
            print("🔊 \(file)")
            
            // Step 3: Retrieve WAV file from server using UUID
            guard let url = URL(string: "http://127.0.0.1:8080/\(file)") else {
                print("Invalid UUID: \(file)")
                continue
            }
            
            do {
                let (data, response) = try await session.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response when retrieving \(file)")
                    continue
                }
                guard httpResponse.statusCode == 200 else {
                    print("Failed to retrieve \(file): status \(httpResponse.statusCode)")
                    continue
                }
                
                // Save to temporary file and play
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(file).wav")
                try data.write(to: tempURL)
                
                let player = try AVAudioPlayer(contentsOf: tempURL)
                player.play()
                while player.isPlaying {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
            } catch {
                print("Failed to play \(file): \(error)")
            }
        }
        server.files = []
    }
}
