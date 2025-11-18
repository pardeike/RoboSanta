import AVFAudio
import Foundation

@MainActor
struct RoboSantaTTS: SantaVoice {
    private static let serverURL = URL(string: "http://127.0.0.1:8080")!
    private static let outputDirectory: URL = {
        do {
            try FileManager.default.createDirectory(at: TTSServer.tempSantaDir, withIntermediateDirectories: true)
        } catch {
            print("Failed to create \(TTSServer.tempSantaDir): \(error)")
        }
        return TTSServer.tempSantaDir
    }()
    private func prepareOutputURL(for fileName: String) -> URL? {
        guard !fileName.isEmpty else { return nil }
        let url = RoboSantaTTS.outputDirectory.appendingPathComponent(fileName)
        do {
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
        guard let destination = prepareOutputURL(for: file) else { return }

        struct Payload: Encodable {
            let file: String
            let voice: String
            let text: String
        }

        var request = URLRequest(url: RoboSantaTTS.serverURL)
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
            TTSServer.files.append(file)
        } catch {
            print("TTS request failed for \(file): \(error)")
        }
    }

    func speak() async {
        for file in TTSServer.files {
            if file.starts(with: "#") {
                let ms = Int(String(file.dropFirst()))!
                try? await Task.sleep(for: .milliseconds(ms))
                continue
            }
            let file = TTSServer.tempSantaDir.appendingPathComponent(file)
            let player = try! AVAudioPlayer(contentsOf: file)
            player.play()
            while player.isPlaying {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        TTSServer.files = []
    }
}
