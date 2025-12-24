import Foundation

/// SantaSpeaker generates conversation sets in the background and saves them to the filesystem queue.
/// The InteractionCoordinator is responsible for playing them when people are engaged.
struct SantaSpeaker {
    
    static let baseSystem = """
Du är en svensk copywriter. Skriv kort, oväntat och tydligt roligare.
Ton: privat hemma, mer humor, busig, lite fräck och flamsig men rumsren.
Var inte överdrivet försiktig, men håll det alltid lämpligt och tryggt (inget som riskerar att flaggas).
Undvik klichéer/stereotyper. En rad per fält. Ok att säga "ho ho ho".
Skriv bara på Svenska.
Du talar till exakt en person rakt framför dig.
Använd "du/din/ditt".
Svara endast med JSON som matchar schemat.
"""

    private static let openAIAPIKey = getAPIKeyFromFile("OPENAI_API_KEY")
        ?? getAPIKey("OpenAI API Key")
        ?? "none"
    
    let passByTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten startar ett snabbt samtal hemma i en privat miljö.")
    let peppTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten lyfter stämningen hemma med mer humor och bus.")
    let quizTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten ställer en ultrakort, lite fräck men rumsren fråga med tre svarsalternativ.")
    let jokeTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten antyder en busig hemlighet och ger en lättsam komplimang.")
    let pointingTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten pekar åt personen hemma för att ge ett kort råd eller en skämtsam varning.")
    
    // let thinker: Think = AppleIntelligence()
    // let thinker: Think = Koala()
    // let thinker: Think = OllamaThink(modelName: "qwen3:8b")
    let thinker: Think = OpenAI(
        modelName: "gpt-5.2",
        baseURL: "https://api.openai.com/v1",
        apiKey: SantaSpeaker.openAIAPIKey
    )
    
    //let voice: SantaVoice = RoboSantaTTS()
    let voice: SantaVoice = ElevenLabs()
    
    /// Queue manager for storing generated conversation sets
    let queueManager: SpeechQueueManager
    
    /// Configuration for queue behavior
    let queueConfig: SpeechQueueConfiguration
    
    /// Creates a SantaSpeaker with the specified queue manager.
    /// - Parameters:
    ///   - queueManager: The queue manager to save conversation sets to
    ///   - queueConfig: Configuration for queue behavior
    init(queueManager: SpeechQueueManager, queueConfig: SpeechQueueConfiguration = .default) {
        self.queueManager = queueManager
        self.queueConfig = queueConfig
    }
    
    /// Legacy initializer for backward compatibility (still plays audio directly)
    init() {
        self.queueManager = SpeechQueueManager(config: .default)
        self.queueConfig = .default
    }
    
    /// Starts the background generation loop.
    public func start() {
        Task { await self.runGenerationLoop() }
    }
    
    /// Legacy run loop that plays audio directly (for backward compatibility)
    public func startLegacy() {
        Task { await self.runLoop() }
    }
    
    // MARK: - Queue-Based Generation Loop
    
    private func runGenerationLoop() async {
        let opts = GenerationOptions(temperature: 0.9, topP: 0.92, topK: 60, repeatPenalty: 1.1)
        
        print("🎅 SantaSpeaker: Starting queue-based generation loop")
        
        while !Task.isCancelled {
            // Check queue size before generating
            queueManager.scanQueue()
            
            if queueManager.shouldPauseGeneration {
                print("🎅 SantaSpeaker: Queue full (\(queueManager.queueCount) sets), waiting...")
                await MainActor.run {
                    DashboardStats.shared.updateGenerationStatus("Kö full, väntar...")
                }
                let pauseNanos = UInt64(queueConfig.queueFullCheckIntervalSeconds) * 1_000_000_000
                try? await Task.sleep(nanoseconds: pauseNanos)
                continue
            }
            
            // Generate a conversation set (logging handled inside)
            _ = await generateConversationSet(options: opts)
            
            // Throttle generation
            if queueConfig.generationThrottleSeconds > 0 {
                await MainActor.run {
                    DashboardStats.shared.updateGenerationStatus("Väntar på nästa...")
                }
                let throttleNanos = UInt64(queueConfig.generationThrottleSeconds) * 1_000_000_000
                try? await Task.sleep(nanoseconds: throttleNanos)
            }
        }
        
        print("🎅 SantaSpeaker: Generation loop ended")
    }
    
    private func generateConversationSet(options opts: GenerationOptions) async -> Bool {
        let randomTopicAction = randomTopicActions.randomElement()!
        let randomTopic = randomTopics.randomElement()!
        
        // Create a new folder for this conversation set
        let timestamp = ConversationSet.generateTimestamp()
        let setFolder = queueConfig.queueDirectory.appendingPathComponent(timestamp)
        print("🗂️ SantaSpeaker: Preparing set \(timestamp)")
        
        do {
            try FileManager.default.createDirectory(at: setFolder, withIntermediateDirectories: true)
        } catch {
            print("🎅 SantaSpeaker: Failed to create set folder: \(error)")
            return false
        }
        
        // Number of interaction types: 0=pepp, 1=greeting, 2=quiz, 3=joke, 4=pointing
        let maxInteractionType = 4
        let interactionType = Int.random(in: 0...maxInteractionType)
        var interactionName = "unknown"
        var success = false
        
        // Update dashboard with generation status and current topic
        let generationNames = ["Pepp", "Hälsning", "Quiz", "Skämt", "Pekning"]
        let statusText = "Genererar \(generationNames[interactionType])..."
        await MainActor.run {
            DashboardStats.shared.updateGenerationStatus(statusText)
            DashboardStats.shared.updateCurrentTopic(randomTopic)
        }
        
        switch interactionType {
        case 0:
            // Pepp Talk - simple single phrase, no farewell needed
            interactionName = "pepp"
            print("🧠 Generating Pepp Talk (\(randomTopic))")
            struct PeppOut: Decodable { let happyPhrase: String }
            do {
                let r: PeppOut = try await thinker.generate(template: peppTemplate, topicAction: randomTopicAction, topic: randomTopic, model: peppTalkSchema, options: opts)
                try writeTypeFile("pepp", to: setFolder)
                try writeTopicFile(randomTopic, to: setFolder)
                success = await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.happyPhrase)
                // No end.wav - pepp talks don't have farewells
            } catch {
                print("🧠 Pepp generation failed: \(error)")
            }
        
        case 1:
            // Greeting with conversation
            interactionName = "greeting"
            print("🧠 Generating Greeting (\(randomTopic))")
            struct GreetOut: Decodable { let helloPhrase, conversationPhrase, goodbyePhrase: String }
            do {
                let r: GreetOut = try await thinker.generate(template: passByTemplate, topicAction: randomTopicAction, topic: randomTopic, model: passByAndGreetSchema, options: opts)
                try writeTypeFile("greeting", to: setFolder)
                try writeTopicFile(randomTopic, to: setFolder)
                let ttsSuccess1 = await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                let ttsSuccess2 = await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), r.conversationPhrase)
                let ttsSuccess3 = await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                success = ttsSuccess1 && ttsSuccess2 && ttsSuccess3
            } catch {
                print("🧠 Greeting generation failed: \(error)")
            }
        
        case 2:
            // Quiz
            interactionName = "quiz"
            print("🧠 Generating Quiz (\(randomTopic))")
            for _ in 1...3 {
                do {
                    let r: QuizOut = try await thinker.generate(template: quizTemplate, topicAction: randomTopicAction, topic: randomTopic, model: quizSchema, options: opts)
                    let (q, a1, a2, a3) = fixQuiz(r)
                    if q.isEmpty || Set([a1,a2,a3]).count < 3 { continue }
                    
                    try writeTypeFile("quiz", to: setFolder)
                    try writeTopicFile(randomTopic, to: setFolder)
                    let ttsSuccess1 = await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                    let ttsSuccess2 = await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), "Tid för en quiz: " + q)
                    let ttsSuccess3 = await generateTTSToFile(setFolder.appendingPathComponent("middle2.wav"), "A: " + a1)
                    let ttsSuccess4 = await generateTTSToFile(setFolder.appendingPathComponent("middle3.wav"), "B: " + a2)
                    let ttsSuccess5 = await generateTTSToFile(setFolder.appendingPathComponent("middle4.wav"), "C: " + a3)
                    let ttsSuccess6 = await generateTTSToFile(setFolder.appendingPathComponent("middle5.wav"), "Svaret är: \(r.correct_answer)")
                    let ttsSuccess7 = await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                    
                    if ttsSuccess1 && ttsSuccess2 && ttsSuccess3 && ttsSuccess4 && ttsSuccess5 && ttsSuccess6 && ttsSuccess7 {
                        success = true
                        break
                    }
                } catch {
                    print("🧠 Quiz generation attempt failed: \(error)")
                }
            }
        
        case 3:
            // Joke
            interactionName = "joke"
            print("🧠 Generating Joke (\(randomTopic))")
            struct JokeOut: Decodable { let helloPhrase, secret, compliment, goodbyePhrase: String }
            do {
                let r: JokeOut = try await thinker.generate(template: jokeTemplate, topicAction: randomTopicAction, topic: randomTopic, model: jokeSchema, options: opts)
                try writeTypeFile("joke", to: setFolder)
                try writeTopicFile(randomTopic, to: setFolder)
                let ttsSuccess1 = await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                let ttsSuccess2 = await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), r.secret)
                let ttsSuccess3 = await generateTTSToFile(setFolder.appendingPathComponent("middle2.wav"), r.compliment)
                let ttsSuccess4 = await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                success = ttsSuccess1 && ttsSuccess2 && ttsSuccess3 && ttsSuccess4
            } catch {
                print("🧠 Joke generation failed: \(error)")
            }
        
        case 4:
            // Pointing - point-and-lecture format
            interactionName = "pointing"
            print("🧠 Generating Pointing (\(randomTopic))")
            struct PointOut: Decodable { let attentionPhrase, lecturePhrase: String }
            do {
                let r: PointOut = try await thinker.generate(template: pointingTemplate, topicAction: randomTopicAction, topic: randomTopic, model: pointingSchema, options: opts)
                try writeTypeFile("pointing", to: setFolder)
                try writeTopicFile(randomTopic, to: setFolder)
                let ttsSuccess1 = await generateTTSToFile(setFolder.appendingPathComponent("attention.wav"), r.attentionPhrase)
                let ttsSuccess2 = await generateTTSToFile(setFolder.appendingPathComponent("lecture.wav"), r.lecturePhrase)
                success = ttsSuccess1 && ttsSuccess2
            } catch {
                print("🧠 Pointing generation failed: \(error)")
            }
            
        default:
            break
        }
        
        // Clean up failed generation
        if !success {
            try? FileManager.default.removeItem(at: setFolder)
            print("🎅 SantaSpeaker: Generation failed for set \(timestamp) [\(interactionName)]")
            await MainActor.run {
                DashboardStats.shared.updateGenerationStatus("Generering misslyckades")
            }
        }
        
        // Refresh queue count and log the updated size
        let newCount = queueManager.scanQueue().count
        if success {
            print("🎅 SantaSpeaker: Generated set \(timestamp) [\(interactionName)] (queue now \(newCount))")
            await MainActor.run {
                DashboardStats.shared.updateGenerationStatus("Klar (\(newCount) i kö)")
            }
        }
        
        return success
    }
    
    /// Writes the interaction type to type.txt in the conversation set folder.
    private func writeTypeFile(_ type: String, to folder: URL) throws {
        let typeFile = folder.appendingPathComponent("type.txt")
        try type.write(to: typeFile, atomically: true, encoding: .utf8)
    }
    
    /// Writes the topic to topic.txt in the conversation set folder.
    private func writeTopicFile(_ topic: String, to folder: URL) throws {
        let topicFile = folder.appendingPathComponent("topic.txt")
        try topic.write(to: topicFile, atomically: true, encoding: .utf8)
    }
    
    /// Generates TTS audio and saves directly to a file.
    /// Returns false if synthesis failed so callers can clean up partial sets.
    /// - Parameters:
    ///   - fileURL: The URL to save the WAV file to
    ///   - text: The text to synthesize
    private func generateTTSToFile(_ fileURL: URL, _ text: String) async -> Bool {
        let cleaned = text.cleanup()
        guard !cleaned.isEmpty else {
            print("TTS generation skipped: empty text for \(fileURL.lastPathComponent)")
            return false
        }
        
        print("📝 TTS: \(fileURL.lastPathComponent) <- \(cleaned)")
        
        if let elevenLabs = voice as? ElevenLabs {
            return await elevenLabs.ttsToFile(fileURL, cleaned)
        }
        
        if let roboSantaTTS = voice as? RoboSantaTTS {
            guard await roboSantaTTS.server.waitUntilReady() else {
                print("TTS server not ready")
                return false
            }
        } else {
            print("Unsupported SantaVoice for file synthesis: \(type(of: voice))")
            return false
        }
        
        struct Payload: Encodable {
            let voice: String
            let text: String
        }
        
        struct Response: Decodable {
            let uuid: String
        }
        
        // Step 1: Generate TTS on server
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8080")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = Payload(voice: "alfons1", text: cleaned)
        request.httpBody = try? JSONEncoder().encode(payload)
        request.timeoutInterval = 300
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("TTS server error")
                return false
            }
            
            let responseData = try JSONDecoder().decode(Response.self, from: data)
            let uuid = responseData.uuid
            
            // Step 2: Download the WAV file
            guard let downloadURL = URL(string: "http://127.0.0.1:8080/\(uuid)") else { return false }
            
            let (wavData, _) = try await session.data(from: downloadURL)
            
            // Step 3: Save to destination
            try wavData.write(to: fileURL)
            // print("💾 Saved: \(fileURL.lastPathComponent)")
            
            return true
        } catch {
            print("TTS generation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Legacy Direct Playback Loop
    
    private func runLoop() async {
        let opts = GenerationOptions(temperature: 0.9, topP: 0.92, topK: 60, repeatPenalty: 1.1)
        while !Task.isCancelled {
            let randomTopicAction = randomTopicActions.randomElement()!
            let randomTopic = randomTopics.randomElement()!
            switch Int.random(in: 0...3) {
                case 0:
                    print("🧠 Pepp Talk (\(randomTopic))")
                    struct PeppOut: Decodable { let happyPhrase: String }
                    do {
                        let r: PeppOut = try await thinker.generate(template: peppTemplate, topicAction: randomTopicAction, topic: randomTopic, model: peppTalkSchema, options: opts)
                        await voice.tts("Happyness", r.happyPhrase)
                    } catch {
                        print(error)
                    }
                
                case 1:
                    print("🧠 Greeting (\(randomTopic))")
                    struct GreetOut: Decodable { let helloPhrase, conversationPhrase, goodbyePhrase: String }
                    do {
                        let r: GreetOut = try await thinker.generate(template: passByTemplate, topicAction: randomTopicAction, topic: randomTopic, model: passByAndGreetSchema, options: opts)
                        await voice.tts("Hello", r.helloPhrase)
                        await voice.tts("Conversation", r.conversationPhrase)
                        await voice.tts("Goodbye", r.goodbyePhrase)
                    } catch {
                        print(error)
                    }

                case 2:
                    print("🧠 Quiz (\(randomTopic))")
                    for _ in 1...3 {
                        do {
                            let r: QuizOut = try await thinker.generate(template: quizTemplate, topicAction: randomTopicAction, topic: randomTopic, model: quizSchema, options: opts)
                            let (q, a1, a2, a3) = fixQuiz(r) // your existing helper
                            if q.isEmpty || Set([a1,a2,a3]).count < 3 { continue }
                            await voice.tts("Hello", r.helloPhrase)
                            await voice.tts("Quiz", q)
                            await voice.tts("Answer1", "A: " + a1)
                            await voice.tts("Answer2", "B: " + a2)
                            await voice.tts("Answer3", "C: " + a3)
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            await voice.tts("Solution", "Svaret är: \(r.correct_answer)")
                            await voice.tts("Goodbye", r.goodbyePhrase)
                            break
                        } catch {
                            print(error)
                        }
                    }

                case 3:
                    print("🧠 Joke (\(randomTopic))")
                    struct JokeOut: Decodable { let helloPhrase, secret, compliment, goodbyePhrase: String }
                    do {
                        let r: JokeOut = try await thinker.generate(template: jokeTemplate, topicAction: randomTopicAction, topic: randomTopic, model: jokeSchema, options: opts)
                        await voice.tts("Hello", r.helloPhrase)
                        await voice.tts("Secret", r.secret)
                        await voice.tts("Compliment", r.compliment)
                        await voice.tts("Goodbye", r.goodbyePhrase)
                    } catch {
                        print(error)
                    }

                default: break
            }
            await voice.speak()
        }
    }
}
