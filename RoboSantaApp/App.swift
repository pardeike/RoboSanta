import FoundationModels
import AVFoundation
import SwiftUI
import Ollama

@available(macOS 11.0, *)
struct MinimalApp: App {
    @StateObject private var camera = CameraManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(camera)
                .onAppear { camera.start() }
                .onDisappear { camera.stop() }
        }
    }
}

@main
struct EntryPoint {
    
    static let baseSystem = """
Du är en svensk copywriter. Skriv kort och oväntat, lite roligt.
Undvik klichéer/stereotyper. En rad per fält. Ok att säga "ho ho ho".
Skriv bara på Svenska.
Du talar till exakt en person rakt framför dig.
Använd "du/din/ditt".
Svara endast med JSON som matchar schemat.
"""
    
    static let passByTemplate = PromptTemplate(
        system: baseSystem,
        scene: "Tomten försöker starta ett snabbt samtal i korridoren."
    )

    static let peppTemplate = PromptTemplate(
        system: baseSystem,
        scene: "Tomten lyfter stämningen på ett personligt sätt."
    )

    static let quizTemplate = PromptTemplate(
        system: baseSystem,
        scene: "Tomten ställer en ultrakort fråga med tre svarsalternativ."
    )

    static let jokeTemplate = PromptTemplate(
        system: baseSystem,
        scene: "Tomten antyder en smakfull hemlighet och ger en stilren komplimang."
    )
    
    private static func backgroundLoop() async {
        let thinker: Think = Koala()
        // let thinker: Think = OllamaThink(modelName: "qwen2.5:7b-instruct")
        // let thinker: Think = AppleIntelligence()
        let opts = GenerationOptions(temperature: 0.9, topP: 0.92, topK: 60, repeatPenalty: 1.1)
        let speaker: Speak = RoboSantaSpeaker() // ElevenLabs()
        while !Task.isCancelled {
            let randomTopicAction = randomTopicActions.randomElement()!
            let randomTopic = randomTopics.randomElement()!
            switch Int.random(in: 0...3) {
                case 0:
                    print("Pepp Talk (\(randomTopic)):")
                    struct PeppOut: Decodable { let happyPhrase: String }
                    do {
                        let r: PeppOut = try await thinker.generate(template: peppTemplate, topicAction: randomTopicAction, topic: randomTopic, model: peppTalkSchema, options: opts)
                        await speaker.say("Happyness", r.happyPhrase)
                    } catch {
                        print(error)
                    }
                
                case 1:
                    print("Greeting (\(randomTopic)):")
                    struct GreetOut: Decodable { let helloPhrase, conversationPhrase, goodbyePhrase: String }
                    do {
                        let r: GreetOut = try await thinker.generate(template: passByTemplate, topicAction: randomTopicAction, topic: randomTopic, model: passByAndGreetSchema, options: opts)
                        await speaker.say("Hello", r.helloPhrase)
                        await speaker.say("Conversation", r.conversationPhrase)
                        await speaker.say("Goodbye", r.goodbyePhrase)
                    } catch {
                        print(error)
                    }

                case 2:
                    print("Quiz (\(randomTopic)):")
                    for _ in 1...3 {
                        do {
                            let r: QuizOut = try await thinker.generate(template: quizTemplate, topicAction: randomTopicAction, topic: randomTopic, model: quizSchema, options: opts)
                            let (q, a1, a2, a3) = fixQuiz(r) // your existing helper
                            if q.isEmpty || Set([a1,a2,a3]).count < 3 { continue }
                            await speaker.say("Hello", r.helloPhrase)
                            await speaker.say("Quiz", q)
                            await speaker.say("Answer 1", "A: " + a1)
                            await speaker.say("Answer 2", "B: " + a2)
                            await speaker.say("Answer 3", "C: " + a3)
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            await speaker.say("Correct Answer", r.correct_answer)
                            await speaker.say("Goodbye", r.goodbyePhrase)
                            break
                        } catch {
                            print(error)
                        }
                    }

                case 3:
                    print("Joke (\(randomTopic)):")
                    struct JokeOut: Decodable { let helloPhrase, secret, compliment, goodbyePhrase: String }
                    do {
                        let r: JokeOut = try await thinker.generate(template: jokeTemplate, topicAction: randomTopicAction, topic: randomTopic, model: jokeSchema, options: opts)
                        await speaker.say("Hello", r.helloPhrase)
                        await speaker.say("Secret", r.secret)
                        await speaker.say("Compliment", r.compliment)
                        await speaker.say("Goodbye", r.goodbyePhrase)
                    } catch {
                        print(error)
                    }

                default: break
            }
            print("")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    
    static func main() async {
        let loopTask = Task.detached(priority: .background) {
            await backgroundLoop()
        }
        MinimalApp.main()
        print("Preparing shutdown")
        loopTask.cancel()
        _ = await loopTask.result
        print("Done")
    }
}

/*
var attached = false
let ch = RCServo()
let handlers = Handlers()
let functions = Functions(ch: ch)

_ = ch.error.addHandler(handlers.error_handler)
_ = ch.attach.addHandler({
    handlers.attach_handler(sender: $0)
    attached = true
})
_ = ch.detach.addHandler(handlers.detach_handler)
_ = ch.velocityChange.addHandler(handlers.velocitychange_handler)
_ = ch.positionChange.addHandler(handlers.positionchange_handler)
_ = ch.targetPositionReached.addHandler(handlers.targetreached_handler)

try ch.setChannel(0)
try ch.setIsHubPortDevice(false)
try ch.setIsLocal(true)
try ch.open()
while !attached { usleep(1000) }

try ch.setMinPulseWidth(550)
try ch.setMaxPulseWidth(2450)
try ch.setMinPosition(0)
try ch.setMaxPosition(1)
try ch.setSpeedRampingState(true)

functions.setVelocityLimit(0.1) // seems not to work
functions.setTargetPosition(0)
functions.engageMotor(true)

functions.setVelocityLimit(35)
while true {
    let pos = Double(arc4random() % 100) / 100.0
    functions.setTargetPosition(pos)
    usleep(1000000)
}

functions.engageMotor(false)
*/




