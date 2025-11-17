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
    
    static let commonSuffix
        = " Vary each time; mostly positive, sometimes lightly cynical or unexpectedly funny. Avoid clichés or stereotypes. Get right to the point. Nothing too corny."
    
    static let passByAndGreetPrompt
        = "Write in Swedish: Something for Santa Claus to say during December." + commonSuffix
    
    static let quizPrompt
        = "Write in Swedish: Santa Claus giving a quiz." + commonSuffix
    
    static let jokePrompt
        = "Write in Swedish: Santa Claus making a tasteful joke or compliment on the person standing in front of him. Make it interesting!" + commonSuffix
    
    private static func backgroundLoop() async {
        let thinker: Think = Ollama(modelName: "gemma3n") // AppleIntelligence() Ollama() OpenAI()
        let speaker: Speak = ElevenLabs() // RoboSantaSpeaker()
        while !Task.isCancelled {
            if let answer = await thinker.generateText(passByAndGreetPrompt, passByAndGreetSchema) {
                await speaker.say("Greeting", answer.value("firstPhrase"))
                switch Int.random(in: 1...3) {
                case 1:
                    await speaker.say("Followup", answer.value("secondPhrase"))
                    await speaker.say("Ending", answer.value("thirdPhrase"))
                case 2:
                    for _ in 1...3 {
                        if let quiz = await thinker.generateText(quizPrompt, quizSchema) {
                            let (q, a1, a2, a3) = fixQuiz(quiz)
                            if q == "" || a1 == a2 || a2 == a3 || a1 == a3 { continue }
                            await speaker.say("Quiz", q)
                            await speaker.say("Answer 1", "A: " + a1)
                            await speaker.say("Answer 2", "B: " + a2)
                            await speaker.say("Answer 3", "C: " + a3)
                            sleep(1)
                            await speaker.say("Ending", quiz.value("ending"))
                            break
                        }
                    }
                    break
                case 3:
                if let answer = await thinker.generateText(jokePrompt, jokeSchema) {
                    await speaker.say("Compliment", answer.value("compliment"))
                    await speaker.say("Buildup", answer.value("buildup"))
                    await speaker.say("Punchline", answer.value("punchline"))
                }
                default:
                    break
                }
                print("")
                sleep(1)
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        /*
         while !Task.isCancelled {
            if let answer = await thinker.generateText(quizPrompt, quizSchema) {
                await speaker.say("Question", answer.value("question"))
                await speaker.say("Answer 1", "A: " + answer.value("answer1"))
                await speaker.say("Answer 2", "B: " + answer.value("answer2"))
                await speaker.say("Answer 3", "C: " + answer.value("answer3"))
                print("")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        */
    }
    
    static func main() async {
        let loopTask = Task.detached(priority: .background) {
            //await backgroundLoop()
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



