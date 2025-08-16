import AVFAudio

//for voice in AVSpeechSynthesisVoice.speechVoices() {
//    print("\(voice.name) — \(voice.identifier) — \(voice.language)")
//}

let text = CommandLine.arguments[1]
let u = AVSpeechUtterance(string: text)
u.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.sv-SE.Oskar")
?? AVSpeechSynthesisVoice(language: "sv-SE")
u.rate = 0.25
u.pitchMultiplier = 0.5
let synth = AVSpeechSynthesizer()
synth.speak(u)
usleep(100000)
while synth.isSpeaking { usleep(10000) }
