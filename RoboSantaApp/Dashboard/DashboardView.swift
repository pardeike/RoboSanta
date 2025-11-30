// DashboardView.swift
// Full-screen Santa-themed dashboard for the physical mode.

import SwiftUI
import Combine
import Charts

/// Santa-themed color palette (red, white, black like our Santa)
enum SantaColors {
    static let background = Color.black
    static let primaryRed = Color(red: 0.85, green: 0.1, blue: 0.1)
    static let secondaryRed = Color(red: 0.6, green: 0.05, blue: 0.05)
    static let accent = Color.white
    static let white = Color.white
    static let cardBackground = Color(white: 0.08)
    static let cardBorder = Color(red: 0.4, green: 0.1, blue: 0.1)
}

/// Main dashboard view for physical mode
struct DashboardView: View {
    @EnvironmentObject var visionSource: VisionDetectionSource
    @ObservedObject var coordinator: RuntimeCoordinator
    let queueManager: SpeechQueueManager
    var interaction: InteractionCoordinator?
    
    @State private var pose = StateMachine.FigurinePose()
    @State private var stats = DashboardStats.shared
    @State private var sessionTime = ""
    @State private var queueCount: Int = 0
    @State private var interactionState: InteractionState = .idle
    @State private var isSpeaking: Bool = false
    @State private var pulseAnimation = false
    
    /// Default initializer using app globals
    init(coordinator: RuntimeCoordinator) {
        self.coordinator = coordinator
        self.queueManager = speechQueueManager
        self.interaction = interactionCoordinator
    }
    
    /// Full initializer for testing
    init(coordinator: RuntimeCoordinator, queueManager: SpeechQueueManager, interaction: InteractionCoordinator?) {
        self.coordinator = coordinator
        self.queueManager = queueManager
        self.interaction = interaction
    }
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - solid black
                SantaColors.background
                    .ignoresSafeArea()
                
                // Snow particle effect overlay
                SnowfallView()
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 16)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 12)
                    
                    // Main content area - fills remaining space
                    HStack(alignment: .top, spacing: 24) {
                        // Left column - Camera and servo info
                        VStack(spacing: 16) {
                            cameraPreviewCard
                            servoInfoCard
                        }
                        .frame(width: geometry.size.width * 0.4)
                        .frame(maxHeight: .infinity)
                        
                        // Middle column - Status and state (fills vertical space)
                        VStack(spacing: 16) {
                            stateCard
                            queueCard
                            generationCard
                            Spacer(minLength: 0)
                        }
                        .frame(width: geometry.size.width * 0.25)
                        .frame(maxHeight: .infinity)
                        
                        // Right column - Statistics and QR (fills vertical space)
                        VStack(spacing: 16) {
                            engagementCard
                            statisticsChartCard
                            qrCodeCard
                            Spacer(minLength: 0)
                        }
                        .frame(width: geometry.size.width * 0.25)
                        .frame(maxHeight: .infinity)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
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
        VStack(spacing: 8) {
            Text("🎅 LEVERANSTOMTE 🎅")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SantaColors.primaryRed, Color(red: 1.0, green: 0.3, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: SantaColors.primaryRed.opacity(0.5), radius: 10)
            
            Text("Ett projekt av LK Arkitektur")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(SantaColors.white.opacity(0.8))
        }
    }
    
    // MARK: - Camera Preview Card
    
    private var cameraPreviewCard: some View {
        DashboardCard(title: "KAMERAVY", icon: "camera.fill") {
            ZStack {
                // Blurred camera preview
                BlurredCameraPreview()
                    .environmentObject(visionSource)
                    .cornerRadius(12)
                
                // Face detection overlay is handled by VisionDetectionSource
                
                // Detection indicator
                if stats.personDetected {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 16, height: 16)
                                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                        value: pulseAnimation
                                    )
                                Text("PERSON UPPTÄCKT")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(12)
                        }
                        Spacer()
                    }
                }
            }
            .frame(minHeight: 250)
        }
    }
    
    // MARK: - Servo Info Card
    
    private var servoInfoCard: some View {
        DashboardCard(title: "SERVOPOSITONER", icon: "gearshape.2.fill") {
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    servoGauge(label: "KROPP", value: pose.bodyAngle, range: -105...105, unit: "°", color: ServoColor.body)
                    servoGauge(label: "HUVUD", value: pose.headAngle, range: -30...30, unit: "°", color: ServoColor.head)
                }
                HStack(spacing: 24) {
                    servoGauge(label: "VÄNSTER ARM", value: pose.leftHand * 100, range: 0...100, unit: "%", color: ServoColor.leftArm)
                    servoGauge(label: "HÖGER ARM", value: pose.rightHand * 100, range: 0...100, unit: "%", color: ServoColor.rightArm)
                }
            }
        }
    }
    
    private func servoGauge(label: String, value: Double, range: ClosedRange<Double>, unit: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: normalizedValue(value, in: range))
                    .stroke(
                        LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: value)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 110, height: 110)
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
            VStack(spacing: 20) {
                // Current state display
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aktuellt läge")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(stateDisplayName(stats.currentStateName))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(stateColor(stats.currentStateName))
                    }
                    Spacer()
                    stateIcon(stats.currentStateName)
                        .font(.system(size: 56))
                        .foregroundColor(stateColor(stats.currentStateName))
                }
                
                Divider()
                    .background(SantaColors.cardBorder)
                
                // Speaking indicator
                HStack {
                    Circle()
                        .fill(isSpeaking ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isSpeaking && pulseAnimation ? 1.3 : 1.0)
                        .animation(
                            isSpeaking ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                            value: pulseAnimation
                        )
                    Text(isSpeaking ? "TALAR" : "TYST")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                // Session time
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SantaColors.primaryRed.opacity(0.8))
                    Text("Session: \(sessionTime)")
                        .font(.system(size: 20, weight: .medium))
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
        case "patrolling": return SantaColors.primaryRed
        case "personDetected": return Color.green
        case "greeting", "farewell": return SantaColors.white
        case "personLost": return .orange
        default:
            if state.hasPrefix("conversing") {
                return Color.green
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
            VStack(spacing: 16) {
                // Queue count with visual indicator
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Väntande samtal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(queueCount)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(queueCount > 0 ? Color.green : .gray)
                    }
                    Spacer()
                    
                    // Queue bar visualization
                    VStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Rectangle()
                                .fill(i < min(queueCount, 5) ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 60, height: 10)
                                .cornerRadius(5)
                        }
                    }
                }
                
                // Queue status
                HStack {
                    Circle()
                        .fill(queueCount > 0 ? Color.green : Color.orange)
                        .frame(width: 14, height: 14)
                    Text(queueCount > 0 ? "Kö aktiv" : "Kö tom")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Generation Card
    
    private var generationCard: some View {
        DashboardCard(title: "AI GENERERING", icon: "sparkles") {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(SantaColors.primaryRed)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(stats.generationStatus)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                
                // Activity indicator
                if stats.generationStatus.contains("Generar") {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: SantaColors.primaryRed))
                        .scaleEffect(1.2)
                }
            }
        }
    }
    
    // MARK: - Statistics Card
    
    // MARK: - Engagement Card
    
    private var engagementCard: some View {
        DashboardCard(title: "ENGAGEMANG", icon: "person.2.fill") {
            VStack(spacing: 20) {
                // Engagement levels
                engagementRow(
                    icon: "figure.walk.departure",
                    label: "Passerade förbi",
                    count: stats.ignoredCount,
                    color: .gray
                )
                
                engagementRow(
                    icon: "eye.fill",
                    label: "Lite nyfikna",
                    count: stats.partialEngagementCount,
                    color: .orange
                )
                
                engagementRow(
                    icon: "star.fill",
                    label: "Stannade hela vägen",
                    count: stats.fullEngagementCount,
                    color: Color.green
                )
                
                Divider()
                    .background(SantaColors.cardBorder)
                
                // Total summary
                HStack {
                    Text("Totalt interaktioner")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(stats.totalInteractions)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(SantaColors.primaryRed)
                }
            }
        }
    }
    
    private func engagementRow(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(color)
        }
    }
    
    // MARK: - Statistics Chart Card
    
    private var statisticsChartCard: some View {
        DashboardCard(title: "SAMTALSTYPER", icon: "chart.bar.fill") {
            VStack(spacing: 16) {
                // Chart using Swift Charts
                Chart {
                    BarMark(
                        x: .value("Typ", "Hälsning"),
                        y: .value("Antal", stats.greetingCount)
                    )
                    .foregroundStyle(SantaColors.primaryRed)
                    
                    BarMark(
                        x: .value("Typ", "Pepp"),
                        y: .value("Antal", stats.peppCount)
                    )
                    .foregroundStyle(Color.white)
                    
                    BarMark(
                        x: .value("Typ", "Quiz"),
                        y: .value("Antal", stats.quizCount)
                    )
                    .foregroundStyle(Color.green)
                    
                    BarMark(
                        x: .value("Typ", "Skämt"),
                        y: .value("Antal", stats.jokeCount)
                    )
                    .foregroundStyle(Color.purple)
                    
                    BarMark(
                        x: .value("Typ", "Pekning"),
                        y: .value("Antal", stats.pointingCount)
                    )
                    .foregroundStyle(Color.orange)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                }
                .frame(height: 160)
            }
        }
    }
    
    private var statisticsCard: some View {
        DashboardCard(title: "STATISTIK", icon: "chart.bar.fill") {
            VStack(spacing: 16) {
                // Total interactions
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Totalt samtal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(stats.totalInteractions)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(SantaColors.primaryRed)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Personer")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(stats.peopleEngaged)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Color.green)
                    }
                }
                
                Divider()
                    .background(SantaColors.cardBorder)
                
                // Interaction type breakdown
                VStack(spacing: 12) {
                    statRow(label: "Hälsningar", count: stats.greetingCount, color: SantaColors.primaryRed)
                    statRow(label: "Pepp", count: stats.peppCount, color: SantaColors.white)
                    statRow(label: "Quiz", count: stats.quizCount, color: Color.green)
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
                .frame(width: 14, height: 14)
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text("\(count)")
                .font(.system(size: 22, weight: .bold).monospacedDigit())
                .foregroundColor(.white)
        }
    }
    
    // MARK: - QR Code Card
    
    private var qrCodeCard: some View {
        DashboardCard(title: "GITHUB", icon: "qrcode") {
            VStack(spacing: 16) {
                QRCodeView(size: 140)
                
                Text("pardeike/RoboSanta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helpers
    
    private func updateSessionTime() {
        sessionTime = stats.formattedDuration
    }
    
    private func updateQueueInfo() {
        queueCount = queueManager.queueCount
        if let ic = interaction {
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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(SantaColors.primaryRed)
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2.0)
            }
            
            // Content
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SantaColors.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(SantaColors.cardBorder, lineWidth: 2)
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
