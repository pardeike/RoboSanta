import FoundationModels
import AVFoundation

@main
struct App {
    
    static let commonSuffix = " Vary each time; mostly positive, sometimes lightly cynical or unexpectedly funny. Avoid clichés or stereotypes. Get right to the point. Nothing too corny."
    
    static let prompt = "Write in Swedish: Something for Santa Claus to say during December." + commonSuffix
    
    static func main() async {
        let thinker: Think = AppleIntelligence() // OpenAI()
        let speaker: Speak = RoboSantaSpeaker() // ElevenLabs()
        while true {
            if let answer = await thinker.generateText(prompt, passByAndGreetSchema) {
                await speaker.say("Greeting", answer.value("firstPhrase"))
                await speaker.say("Followup", answer.value("secondPhrase"))
                await speaker.say("Ending", answer.value("thirdPhrase"))
                print("")
                sleep(1)
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
