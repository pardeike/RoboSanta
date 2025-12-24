import Foundation
import AVFoundation
import AVFAudio
import Security

@MainActor
struct ElevenLabs: SantaVoice {
    
    // DEFAULT VOICES (stability:0.3,similarity:1,style:0,speed:1.08)
    // let voiceID = "2gPFXx8pN3Avh27Dw5Ma" // Oxley
    
    // CUSTOM VOICES (stability:0,similarity:0,style:0,speed:0.7)
    // let voiceID = "xVgWNga54iJ6TyFXlpOC" // Björn Gustafson
    // let voiceID = "VyHbBNJj3GOP6WZmSX5B" // ComSenze
    let voiceID = "9rVZvksFwnsjmbxBdx7z" // GW Persson
    
    //let stability = 0.3
    //let similarity = 1.0
    //let style = 0.0
    //let speed = 1.08
    
    let stability = 0.0
    let similarity = 0.0
    let style = 0.0
    let speed = 0.7
    
    let outputFormat = "mp3_22050_32"
    let modelID = "eleven_flash_v2_5" // eleven_turbo_v2_5, eleven_multilingual_v2"
    let language = "sv"
    
    struct VoiceSettings: Encodable {
        let stability: Double
        let use_speaker_boost: Bool
        let similarity_boost: Double
        let style: Double
        let speed: Double
    }
    
    struct Input: Encodable {
        let text: String
        let model_id: String
        let language_code: String
        let voice_settings: VoiceSettings
        let previous_text: String
    }

    private func makeRequest(apiKey: String, text: String) throws -> URLRequest {
        let url = "https://api-global-preview.elevenlabs.io/v1/text-to-speech/\(voiceID)?output_format=\(outputFormat)&optimize_streaming_latency=4"
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Input(
            text: text,
            model_id: modelID,
            language_code: language,
            voice_settings: VoiceSettings(
                stability: stability,
                use_speaker_boost: true,
                similarity_boost: similarity,
                style: style,
                speed: speed
            ),
            previous_text: "Ho, ho, ho. God Jul!"
        ))
        return req
    }
    
    func tts(_ file: String, _ text: String) async {
        guard let apiKey = getAPIKey("Elevenlabs API Key"), !apiKey.isEmpty else {
            print("Missing ElevenLabs API key")
            return
        }
        let cleaned = text.cleanup()
        print("\(file): \(cleaned)")
        do {
            let req = try makeRequest(apiKey: apiKey, text: cleaned)
            if let (data, response) = try? await URLSession.shared.data(for: req) {
                guard let urlResponse = response as? HTTPURLResponse else { return }
                guard urlResponse.statusCode == 200 else { return }
                let player = try AVAudioPlayer(data: data)
                player.play()
                while player.isPlaying { usleep(100000) }
            }
        } catch {
            print(error)
        }
    }

    func speak() async {}

    func ttsToFile(_ fileURL: URL, _ text: String) async -> Bool {
        guard let apiKey = getAPIKey("Elevenlabs API Key"), !apiKey.isEmpty else {
            print("Missing ElevenLabs API key")
            return false
        }
        let cleaned = text.cleanup()
        guard !cleaned.isEmpty else {
            print("TTS generation skipped: empty text for \(fileURL.lastPathComponent)")
            return false
        }
        do {
            let req = try makeRequest(apiKey: apiKey, text: cleaned)
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let urlResponse = response as? HTTPURLResponse else { return false }
            guard urlResponse.statusCode == 200 else {
                print("ElevenLabs TTS server error: \(urlResponse.statusCode)")
                return false
            }
            try data.write(to: fileURL)
            return true
        } catch {
            print("ElevenLabs TTS generation failed: \(error)")
            return false
        }
    }
}
