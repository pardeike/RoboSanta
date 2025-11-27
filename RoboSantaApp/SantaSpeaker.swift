import Foundation

/// SantaSpeaker generates conversation sets in the background and saves them to the filesystem queue.
/// The InteractionCoordinator is responsible for playing them when people are engaged.
struct SantaSpeaker {
    
    static let baseSystem = """
Du är en svensk copywriter. Skriv kort och oväntat, lite roligt.
Undvik klichéer/stereotyper. En rad per fält. Ok att säga "ho ho ho".
Skriv bara på Svenska.
Du talar till exakt en person rakt framför dig.
Använd "du/din/ditt".
Svara endast med JSON som matchar schemat.
"""
    
    let passByTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten försöker starta ett snabbt samtal i korridoren.")
    let peppTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten lyfter stämningen på ett personligt sätt.")
    let quizTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten ställer en ultrakort fråga med tre svarsalternativ.")
    let jokeTemplate = PromptTemplate(system: SantaSpeaker.baseSystem, scene: "Tomten antyder en smakfull hemlighet och ger en stilren komplimang.")
    
    let thinker: Think = AppleIntelligence()
    // static let thinker: Think = Koala()
    // static let thinker: Think = OllamaThink(modelName: "qwen3:8b")
    
    let voice: SantaVoice = RoboSantaTTS()
    // static let santa: SantaVoice = ElevenLabs()
    
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
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                continue
            }
            
            // Generate a conversation set
            let success = await generateConversationSet(options: opts)
            
            if success {
                print("🎅 SantaSpeaker: Generated conversation set, queue size: \(queueManager.queueCount + 1)")
            }
            
            // Throttle generation
            let throttleNanos = UInt64(queueConfig.generationThrottleSeconds) * 1_000_000_000
            try? await Task.sleep(nanoseconds: throttleNanos)
        }
        
        print("🎅 SantaSpeaker: Generation loop ended")
    }
    
    private func generateConversationSet(options opts: GenerationOptions) async -> Bool {
        let randomTopicAction = randomTopicActions.randomElement()!
        let randomTopic = randomTopics.randomElement()!
        
        // Create a new folder for this conversation set
        let timestamp = ConversationSet.generateTimestamp()
        let setFolder = queueConfig.queueDirectory.appendingPathComponent(timestamp)
        
        do {
            try FileManager.default.createDirectory(at: setFolder, withIntermediateDirectories: true)
        } catch {
            print("🎅 SantaSpeaker: Failed to create set folder: \(error)")
            return false
        }
        
        let interactionType = Int.random(in: 0...3)
        var success = false
        
        switch interactionType {
        case 0:
            // Pepp Talk - simple single phrase (start + end only)
            print("🧠 Generating Pepp Talk (\(randomTopic))")
            struct PeppOut: Decodable { let happyPhrase: String }
            do {
                let r: PeppOut = try await thinker.generate(template: peppTemplate, topicAction: randomTopicAction, topic: randomTopic, model: peppTalkSchema, options: opts)
                // For simple pepp talk, use happy phrase as both start and end
                await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.happyPhrase)
                await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), "Ha det bra!")
                success = true
            } catch {
                print("🧠 Pepp generation failed: \(error)")
            }
            
        case 1:
            // Greeting with conversation
            print("🧠 Generating Greeting (\(randomTopic))")
            struct GreetOut: Decodable { let helloPhrase, conversationPhrase, goodbyePhrase: String }
            do {
                let r: GreetOut = try await thinker.generate(template: passByTemplate, topicAction: randomTopicAction, topic: randomTopic, model: passByAndGreetSchema, options: opts)
                await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), r.conversationPhrase)
                await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                success = true
            } catch {
                print("🧠 Greeting generation failed: \(error)")
            }
            
        case 2:
            // Quiz
            print("🧠 Generating Quiz (\(randomTopic))")
            for _ in 1...3 {
                do {
                    let r: QuizOut = try await thinker.generate(template: quizTemplate, topicAction: randomTopicAction, topic: randomTopic, model: quizSchema, options: opts)
                    let (q, a1, a2, a3) = fixQuiz(r)
                    if q.isEmpty || Set([a1,a2,a3]).count < 3 { continue }
                    
                    await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                    await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), q)
                    await generateTTSToFile(setFolder.appendingPathComponent("middle2.wav"), "A: " + a1)
                    await generateTTSToFile(setFolder.appendingPathComponent("middle3.wav"), "B: " + a2)
                    await generateTTSToFile(setFolder.appendingPathComponent("middle4.wav"), "C: " + a3)
                    await generateTTSToFile(setFolder.appendingPathComponent("middle5.wav"), "Svaret är: \(r.correct_answer)")
                    await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                    success = true
                    break
                } catch {
                    print("🧠 Quiz generation attempt failed: \(error)")
                }
            }
            
        case 3:
            // Joke
            print("🧠 Generating Joke (\(randomTopic))")
            struct JokeOut: Decodable { let helloPhrase, secret, compliment, goodbyePhrase: String }
            do {
                let r: JokeOut = try await thinker.generate(template: jokeTemplate, topicAction: randomTopicAction, topic: randomTopic, model: jokeSchema, options: opts)
                await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.helloPhrase)
                await generateTTSToFile(setFolder.appendingPathComponent("middle1.wav"), r.secret)
                await generateTTSToFile(setFolder.appendingPathComponent("middle2.wav"), r.compliment)
                await generateTTSToFile(setFolder.appendingPathComponent("end.wav"), r.goodbyePhrase)
                success = true
            } catch {
                print("🧠 Joke generation failed: \(error)")
            }
            
        default:
            break
        }
        
        // Clean up failed generation
        if !success {
            try? FileManager.default.removeItem(at: setFolder)
        }
        
        return success
    }
    
    /// Generates TTS audio and saves directly to a file.
    /// - Parameters:
    ///   - fileURL: The URL to save the WAV file to
    ///   - text: The text to synthesize
    private func generateTTSToFile(_ fileURL: URL, _ text: String) async {
        let cleaned = text.cleanup()
        guard !cleaned.isEmpty else { return }
        
        print("📝 TTS: \(fileURL.lastPathComponent) <- \(cleaned)")
        
        guard await (voice as? RoboSantaTTS)?.server.waitUntilReady() ?? true else {
            print("TTS server not ready")
            return
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
                return
            }
            
            let responseData = try JSONDecoder().decode(Response.self, from: data)
            let uuid = responseData.uuid
            
            // Step 2: Download the WAV file
            guard let downloadURL = URL(string: "http://127.0.0.1:8080/\(uuid)") else { return }
            
            let (wavData, _) = try await session.data(from: downloadURL)
            
            // Step 3: Save to destination
            try wavData.write(to: fileURL)
            print("💾 Saved: \(fileURL.lastPathComponent)")
            
        } catch {
            print("TTS generation failed: \(error)")
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
