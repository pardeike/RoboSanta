import FoundationModels
import AVFoundation
import SwiftUI

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
    
    static let prompt
        = "You are a genius Swedish copywriter. You write exceptional good and unconventional dialog. You create incredible brief, positive and sometimes lightly cynical dialog. You avoid clichés or stereotypes and get right to the point. Your task is to write things to say by a Swedish Santa Claus standing in a corridor of a large Swedish government organisation (its a diverse IT department) and your scene is when Santa meets a passing office worker. Funny as you are you made a bet that you can smuggle in something about [topic] into your writing without anybody noticing. Output must be in Swedish only and contain just the phrases. Here is your scene:"
    
    private static func backgroundLoop() async {
        let thinker: Think = Ollama(modelName: "qwen3:14b") // AppleIntelligence() Ollama() OpenAI()
        let speaker: Speak = RoboSantaSpeaker() // ElevenLabs()
        while !Task.isCancelled {
            let randomTopicAction = randomTopicActions.randomElement()!
            let randomTopic = randomTopics.randomElement()!
            switch Int.random(in: 0...0) {
                case 0:
                    if let result = await thinker.generateText(prompt, randomTopicAction, randomTopic, peppTalkSchema) {
                        await speaker.say("Happyness", result.value("happyPhrase"))
                    }
                case 1:
                    if let result = await thinker.generateText(prompt, randomTopicAction, randomTopic, passByAndGreetSchema) {
                        await speaker.say("Hello", result.value("helloPhrase"))
                        await speaker.say("Conversation", result.value("conversationPhrase"))
                        await speaker.say("Goodbye", result.value("goodbyePhrase"))
                    }
                case 2:
                    for _ in 1...3 {
                        if let result = await thinker.generateText(prompt, randomTopicAction, randomTopic, quizSchema) {
                            let (q, a1, a2, a3) = fixQuiz(result)
                            if q == "" || a1 == a2 || a2 == a3 || a1 == a3 { continue }
                            await speaker.say("Hello", result.value("helloPhrase"))
                            await speaker.say("Quiz", q)
                            await speaker.say("Answer 1", "A: " + a1)
                            await speaker.say("Answer 2", "B: " + a2)
                            await speaker.say("Answer 3", "C: " + a3)
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            await speaker.say("Correct Answer", result.value("correct_answer"))
                            await speaker.say("Goodbye", result.value("goodbyePhrase"))
                            break
                        }
                    }
                    break
                case 3:
                    if let result = await thinker.generateText(prompt, randomTopicAction, randomTopic, jokeSchema) {
                        await speaker.say("Hello", result.value("helloPhrase"))
                        await speaker.say("Secret", result.value("secret"))
                        await speaker.say("Compliment", result.value("compliment"))
                        await speaker.say("Goodbye", result.value("goodbyePhrase"))
                    }
                default:
                    break
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



