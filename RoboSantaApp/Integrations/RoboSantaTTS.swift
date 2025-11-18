import AVFAudio
import Foundation

let tempSantaDir = URL(fileURLWithPath: "/tmp/santa")

@MainActor
struct RoboSantaTTS: SantaVoice {
    let server = TTSServer()
    
    private func prepareOutputURL(for fileName: String) -> URL? {
        guard !fileName.isEmpty else { return nil }
        let outputName = fileName.lowercased().hasSuffix(".wav") ? fileName : "\(fileName).wav"
        let url = tempSantaDir.appendingPathComponent(outputName)
        do {
            try FileManager.default.createDirectory(at: tempSantaDir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Failed to clear existing TTS output \(url.path): \(error)")
        }
        return url
    }

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
        print("\(file): \(text)")
        guard let destination = prepareOutputURL(for: file) else { return }
        guard await server.waitUntilReady() else {
            print("TTS server not ready for \(file)")
            return
        }

        struct Payload: Encodable {
            let file: String
            let voice: String
            let text: String
        }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:8080")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = Payload(file: destination.path, voice: "alfons1.wav", text: cleaned)
        request.httpBody = try? JSONEncoder().encode(payload)
        request.timeoutInterval = 300

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid TTS server response for \(file)")
                return
            }
            guard httpResponse.statusCode == 200 else {
                print("TTS server responded with status \(httpResponse.statusCode) for \(file)")
                return
            }
            //let player = try AVAudioPlayer(contentsOf: destination)
            //player.play()
            //while player.isPlaying { usleep(100_000) }
            server.files.append(destination.lastPathComponent)
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
            let file = tempSantaDir.appendingPathComponent(file)
            let player = try! AVAudioPlayer(contentsOf: file)
            player.play()
            while player.isPlaying {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        server.files = []
    }
}
