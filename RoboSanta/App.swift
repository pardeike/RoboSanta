import FoundationModels
import AVFoundation

@main
struct App {
    
    static let prompt = "Write in Swedish: one very short line (max 25 words) for a Santa figure in an office corridor to say to passersby. Vary each time; mostly positive, sometimes lightly cynical or unexpectedly funny. Avoid clichés/stereotypes; not corny; no “ho ho ho” or emojis. EXACTLY one sentence, one variant. Output ONLY the line—no quotes, explanations, or meta."
    
    static func main() async {
        let thinker: Think = AppleIntelligence()
        let speaker: Speak = RoboSantaSpeaker() // ElevenLabs()
        while true {
            print("Thinking")
            if let phrase = await thinker.generateText(prompt) {
                print("Speaking: \(phrase)")
                await speaker.say(phrase)
                print("Done")
            }
        }
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
