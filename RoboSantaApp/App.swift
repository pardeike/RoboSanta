import Foundation
import FoundationModels
import AVFoundation
import SwiftUI
import Combine
import Ollama

/// Set to true to keep the legacy 90° portrait camera rotation; landscape is default.
private let portraitCameraMode = false

/// The runtime coordinator for Santa figurine control.
/// This replaces the global `santa` StateMachine with a higher-level abstraction.
@MainActor
let coordinator = RuntimeCoordinator(
    runtime: .virtual,
    settings: StateMachine.Settings.default.withCameraHorizontalFOV(
        portraitCameraMode ? 60 : 90
    )
)

@available(macOS 11.0, *)
struct MinimalApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if coordinator.detectionSource.supportsPreview,
                   let visionSource = coordinator.detectionSource as? VisionDetectionSource {
                    // Physical mode with camera preview
                    ContentView()
                        .environmentObject(visionSource)
                } else {
                    // Virtual mode - show a placeholder view or minimal UI
                    VirtualModeView(coordinator: coordinator)
                }
            }
            .task {
                if let source = coordinator.detectionSource as? VisionDetectionSource {
                    source.portraitModeEnabled = portraitCameraMode
                }
                do {
                    try await coordinator.start()
                    print("🎅 RoboSanta started in \(coordinator.currentRuntime) mode")
                } catch {
                    print("Failed to start coordinator: \(error)")
                }
            }
        }
    }
}

/// Placeholder view for virtual mode (no camera preview needed)
struct VirtualModeView: View {
    @ObservedObject var coordinator: RuntimeCoordinator
    @State private var renderer = SantaPreviewRenderer()
    @State private var pose = StateMachine.FigurinePose()
    @State private var zoomScale: Double = 0.5
    @State private var azimuthDegrees: Double = -80
    @State private var isPersonHidden: Bool = false
    @StateObject private var dataBuffer = ServoDataBuffer(maxPoints: 200)

    private var personStatesPublisher: AnyPublisher<PersonState, Never> {
        if let virtualSource = coordinator.detectionSource as? VirtualDetectionSource {
            return virtualSource.personStates
        }
        return Empty().eraseToAnyPublisher()
    }
    
    private func poseLabel(_ title: String, value: String, backgroundColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            Text(value)
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(6)
    }
    
    private func updateCamera() {
        renderer.updateCamera(
            azimuthDegrees: 360 - azimuthDegrees,
            zoomScale: 2 - zoomScale
        )
    }
    
    private func updatePersonHidden() {
        renderer.setPersonDimmed(isPersonHidden)
        if let virtualSource = coordinator.detectionSource as? VirtualDetectionSource {
            virtualSource.forcePersonHidden = isPersonHidden
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Top half: 3D Santa Preview
                VStack(spacing: 4) {
                    VirtualSantaPreview(zoomScale: $zoomScale, azimuthDegrees: $azimuthDegrees, isPersonHidden: $isPersonHidden, renderer: renderer)
                }
                .frame(height: geometry.size.height * 0.48)
                
                // Bottom half: Camera feed (left) and Value plotter (right)
                HStack(spacing: 12) {
                    // Left side: Virtual camera feed
                    if let previewSource = coordinator.detectionSource as? DetectionPreviewProviding {
                        DetectionPreview(source: previewSource)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    // Right side: Value plotter
                    ValuePlotter(buffer: dataBuffer)
                        .cornerRadius(12)
                }
                .frame(height: geometry.size.height * 0.38)
                
                // Bottom: Pose labels with colored backgrounds
                HStack(spacing: 8) {
                    poseLabel("Body", value: String(format: "%.1f°", pose.bodyAngle), backgroundColor: ServoColor.bodyBackground)
                    poseLabel("Head", value: String(format: "%.1f°", pose.headAngle), backgroundColor: ServoColor.headBackground)
                    poseLabel("Left arm", value: String(format: "%.2f", pose.leftHand), backgroundColor: ServoColor.leftArmBackground)
                    poseLabel("Right arm", value: String(format: "%.2f", pose.rightHand), backgroundColor: ServoColor.rightArmBackground)
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 600)
        .onAppear {
            let snapshot = coordinator.stateMachine.currentPose()
            pose = snapshot
            renderer.apply(pose: snapshot)
            updateCamera()
        }
        .onChange(of: zoomScale) { _, _ in updateCamera() }
        .onChange(of: azimuthDegrees) { _, _ in updateCamera() }
        .onChange(of: isPersonHidden) { _, _ in updatePersonHidden() }
        .onReceive(coordinator.poseUpdates.receive(on: RunLoop.main)) { newPose in
            pose = newPose
            renderer.apply(pose: newPose)
            dataBuffer.addDataPoint(pose: newPose)
        }
        .onReceive(personStatesPublisher.receive(on: RunLoop.main)) { state in
            renderer.applyPerson(state: state.isPresent ? state : nil)
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
    
    static let passByTemplate = PromptTemplate(system: baseSystem, scene: "Tomten försöker starta ett snabbt samtal i korridoren.")
    static let peppTemplate = PromptTemplate(system: baseSystem, scene: "Tomten lyfter stämningen på ett personligt sätt.")
    static let quizTemplate = PromptTemplate(system: baseSystem, scene: "Tomten ställer en ultrakort fråga med tre svarsalternativ.")
    static let jokeTemplate = PromptTemplate(system: baseSystem, scene: "Tomten antyder en smakfull hemlighet och ger en stilren komplimang.")
    
    // static let thinker: Think = Koala()
    // static let thinker: Think = OllamaThink(modelName: "qwen3:8b")
    static let thinker: Think = AppleIntelligence()
    
    static let voice: SantaVoice = RoboSantaTTS()
    // static let santa: SantaVoice = ElevenLabs()
    
    private static func backgroundLoop() async {
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
            print("")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    
    static func main() async {
        // Coordinator handles startup via SwiftUI lifecycle
        MinimalApp.main()
        print("Preparing shutdown")
        await coordinator.stop()
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
