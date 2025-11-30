// DashboardView.swift
// Full-screen Santa-themed dashboard for the physical mode.

import SwiftUI
import Combine

/// Santa-themed color palette
enum SantaColors {
    static let background = Color(red: 0.08, green: 0.06, blue: 0.1)
    static let primaryRed = Color(red: 0.8, green: 0.15, blue: 0.15)
    static let secondaryRed = Color(red: 0.6, green: 0.1, blue: 0.1)
    static let gold = Color(red: 0.85, green: 0.7, blue: 0.3)
    static let green = Color(red: 0.2, green: 0.5, blue: 0.25)
    static let white = Color.white
    static let cardBackground = Color(white: 0.12)
    static let cardBorder = Color(white: 0.2)
}

/// Main dashboard view for physical mode
struct DashboardView: View {
    @EnvironmentObject var visionSource: VisionDetectionSource
    @ObservedObject var coordinator: RuntimeCoordinator
    @State private var pose = StateMachine.FigurinePose()
    @State private var stats = DashboardStats.shared
    @State private var sessionTime = ""
    @State private var queueCount: Int = 0
    @State private var interactionState: InteractionState = .idle
    @State private var isSpeaking: Bool = false
    @State private var pulseAnimation = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        SantaColors.background,
                        Color(red: 0.12, green: 0.08, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Snow particle effect overlay
                SnowfallView()
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                    
                    // Main content area
                    HStack(spacing: 24) {
                        // Left column - Camera and servo info
                        VStack(spacing: 20) {
                            cameraPreviewCard
                            servoInfoCard
                        }
                        .frame(width: geometry.size.width * 0.4)
                        
                        // Middle column - Status and state
                        VStack(spacing: 20) {
                            stateCard
                            queueCard
                            generationCard
                        }
                        .frame(width: geometry.size.width * 0.25)
                        
                        // Right column - Statistics and QR
                        VStack(spacing: 20) {
                            statisticsCard
                            qrCodeCard
                        }
                        .frame(width: geometry.size.width * 0.25)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    
                    Spacer()
                }
            }
        }
        .onReceive(coordinator.poseUpdates.receive(on: RunLoop.main)) { newPose in
            pose = newPose
        }
        .onReceive(timer) { _ in
            updateSessionTime()
            updateQueueInfo()
        }
        .onAppear {
            stats.connectToStateMachine(coordinator.stateMachine)
            pulseAnimation = true
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("LEVERANSTOMTE")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SantaColors.gold, Color(red: 1.0, green: 0.85, blue: 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: SantaColors.gold.opacity(0.5), radius: 10)
            
            Text("Ett projekt av LK Arkitektur")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(SantaColors.white.opacity(0.7))
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Camera Preview Card
    
    private var cameraPreviewCard: some View {
        DashboardCard(title: "KAMERAVY", icon: "camera.fill") {
            ZStack {
                // Blurred camera preview
                BlurredCameraPreview()
                    .environmentObject(visionSource)
                    .cornerRadius(8)
                
                // Face detection overlay is handled by VisionDetectionSource
                
                // Detection indicator
                if stats.personDetected {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(SantaColors.green)
                                    .frame(width: 10, height: 10)
                                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                        value: pulseAnimation
                                    )
                                Text("PERSON UPPTÄCKT")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(minHeight: 200)
        }
    }
    
    // MARK: - Servo Info Card
    
    private var servoInfoCard: some View {
        DashboardCard(title: "SERVOPOSITONER", icon: "gearshape.2.fill") {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    servoGauge(label: "KROPP", value: pose.bodyAngle, range: -105...105, unit: "°", color: ServoColor.body)
                    servoGauge(label: "HUVUD", value: pose.headAngle, range: -30...30, unit: "°", color: ServoColor.head)
                }
                HStack(spacing: 16) {
                    servoGauge(label: "VÄNSTER ARM", value: pose.leftHand * 100, range: 0...100, unit: "%", color: ServoColor.leftArm)
                    servoGauge(label: "HÖGER ARM", value: pose.rightHand * 100, range: 0...100, unit: "%", color: ServoColor.rightArm)
                }
            }
        }
    }
    
    private func servoGauge(label: String, value: Double, range: ClosedRange<Double>, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.6))
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: normalizedValue(value, in: range))
                    .stroke(
                        LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: value)
                
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 80, height: 80)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func normalizedValue(_ value: Double, in range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    // MARK: - State Card
    
    private var stateCard: some View {
        DashboardCard(title: "TILLSTÅND", icon: "cpu.fill") {
            VStack(spacing: 16) {
                // Current state display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aktuellt läge")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(stateDisplayName(stats.currentStateName))
                            .font(.title2.bold())
                            .foregroundColor(stateColor(stats.currentStateName))
                    }
                    Spacer()
                    stateIcon(stats.currentStateName)
                        .font(.system(size: 32))
                        .foregroundColor(stateColor(stats.currentStateName))
                }
                
                Divider()
                    .background(SantaColors.cardBorder)
                
                // Speaking indicator
                HStack {
                    Circle()
                        .fill(isSpeaking ? SantaColors.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isSpeaking && pulseAnimation ? 1.3 : 1.0)
                        .animation(
                            isSpeaking ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                            value: pulseAnimation
                        )
                    Text(isSpeaking ? "TALAR" : "TYST")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                // Session time
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(SantaColors.gold.opacity(0.7))
                    Text("Session: \(sessionTime)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
        }
    }
    
    private func stateDisplayName(_ state: String) -> String {
        switch state {
        case "idle": return "Vilar"
        case "patrolling": return "Patrullerar"
        case "personDetected": return "Person upptäckt"
        case "greeting": return "Hälsar"
        case "farewell": return "Avsked"
        case "personLost": return "Person försvann"
        default:
            if state.hasPrefix("conversing") {
                return "Samtalar"
            }
            return state.capitalized
        }
    }
    
    private func stateColor(_ state: String) -> Color {
        switch state {
        case "idle": return .gray
        case "patrolling": return SantaColors.gold
        case "personDetected": return SantaColors.green
        case "greeting", "farewell": return SantaColors.primaryRed
        case "personLost": return .orange
        default:
            if state.hasPrefix("conversing") {
                return SantaColors.green
            }
            return .white
        }
    }
    
    private func stateIcon(_ state: String) -> some View {
        let iconName: String
        switch state {
        case "idle": iconName = "moon.zzz.fill"
        case "patrolling": iconName = "eye.fill"
        case "personDetected": iconName = "person.fill.checkmark"
        case "greeting": iconName = "hand.wave.fill"
        case "farewell": iconName = "hand.raised.fill"
        case "personLost": iconName = "person.fill.xmark"
        default:
            if state.hasPrefix("conversing") {
                iconName = "bubble.left.and.bubble.right.fill"
            } else {
                iconName = "questionmark.circle.fill"
            }
        }
        return Image(systemName: iconName)
    }
    
    // MARK: - Queue Card
    
    private var queueCard: some View {
        DashboardCard(title: "SAMTALSKÖ", icon: "text.bubble.fill") {
            VStack(spacing: 12) {
                // Queue count with visual indicator
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Väntande samtal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(queueCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(queueCount > 0 ? SantaColors.green : .gray)
                    }
                    Spacer()
                    
                    // Queue bar visualization
                    VStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            Rectangle()
                                .fill(i < min(queueCount, 5) ? SantaColors.green : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 6)
                                .cornerRadius(3)
                        }
                    }
                }
                
                // Queue status
                HStack {
                    Circle()
                        .fill(queueCount > 0 ? SantaColors.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(queueCount > 0 ? "Kö aktiv" : "Kö tom")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Generation Card
    
    private var generationCard: some View {
        DashboardCard(title: "AI GENERERING", icon: "sparkles") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(SantaColors.gold)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(stats.generationStatus)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                
                // Activity indicator
                if stats.generationStatus.contains("Generar") {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: SantaColors.gold))
                        .scaleEffect(0.8)
                }
            }
        }
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        DashboardCard(title: "STATISTIK", icon: "chart.bar.fill") {
            VStack(spacing: 16) {
                // Total interactions
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Totalt samtal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(stats.totalInteractions)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(SantaColors.gold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Personer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(stats.peopleEngaged)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(SantaColors.green)
                    }
                }
                
                Divider()
                    .background(SantaColors.cardBorder)
                
                // Interaction type breakdown
                VStack(spacing: 8) {
                    statRow(label: "Hälsningar", count: stats.greetingCount, color: SantaColors.primaryRed)
                    statRow(label: "Pepp", count: stats.peppCount, color: SantaColors.gold)
                    statRow(label: "Quiz", count: stats.quizCount, color: SantaColors.green)
                    statRow(label: "Skämt", count: stats.jokeCount, color: .purple)
                    statRow(label: "Pekningar", count: stats.pointingCount, color: .orange)
                }
            }
        }
    }
    
    private func statRow(label: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text("\(count)")
                .font(.caption.bold().monospacedDigit())
                .foregroundColor(.white)
        }
    }
    
    // MARK: - QR Code Card
    
    private var qrCodeCard: some View {
        DashboardCard(title: "GITHUB", icon: "qrcode") {
            VStack(spacing: 12) {
                QRCodeView(size: 120)
                
                Text("pardeike/RoboSanta")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helpers
    
    private func updateSessionTime() {
        sessionTime = stats.formattedDuration
    }
    
    private func updateQueueInfo() {
        queueCount = speechQueueManager.queueCount
        if let ic = interactionCoordinator {
            stats.updateState(ic.state)
            isSpeaking = ic.isSpeaking
        }
    }
}

// MARK: - Dashboard Card Component

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(SantaColors.gold)
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
            }
            
            // Content
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SantaColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SantaColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Blurred Camera Preview

struct BlurredCameraPreview: NSViewRepresentable {
    @EnvironmentObject var visionSource: VisionDetectionSource
    
    func makeNSView(context: Context) -> BlurredPreviewHostView {
        let view = BlurredPreviewHostView()
        visionSource.attach(to: view.rootLayer)
        return view
    }
    
    func updateNSView(_ nsView: BlurredPreviewHostView, context: Context) {
        // Layer autoresizes; nothing to do.
    }
}

final class BlurredPreviewHostView: NSView {
    let rootLayer = CALayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = rootLayer
        // Camera preview with face detection overlay
        // The blur is subtle to keep the preview visible but not distracting
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Snowfall Effect

struct SnowfallView: View {
    @State private var flakes: [Snowflake] = []
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    struct Snowflake: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let size: CGFloat
        let speed: CGFloat
        let drift: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(flakes) { flake in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: flake.size, height: flake.size)
                        .position(x: flake.x, y: flake.y)
                        .blur(radius: flake.size > 3 ? 0 : 1)
                }
            }
            .onAppear {
                // Initialize snowflakes
                for _ in 0..<30 {
                    flakes.append(Snowflake(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height),
                        size: CGFloat.random(in: 2...5),
                        speed: CGFloat.random(in: 0.3...1.0),
                        drift: CGFloat.random(in: -0.3...0.3)
                    ))
                }
            }
            .onReceive(timer) { _ in
                for i in flakes.indices {
                    flakes[i].y += flakes[i].speed
                    flakes[i].x += flakes[i].drift
                    
                    // Reset snowflake when it goes off screen
                    if flakes[i].y > geometry.size.height + 10 {
                        flakes[i].y = -10
                        flakes[i].x = CGFloat.random(in: 0...geometry.size.width)
                    }
                    if flakes[i].x < -10 {
                        flakes[i].x = geometry.size.width + 10
                    } else if flakes[i].x > geometry.size.width + 10 {
                        flakes[i].x = -10
                    }
                }
            }
        }
    }
}
