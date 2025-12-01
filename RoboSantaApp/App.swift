import SwiftUI

/// Set to true to keep the legacy 90° portrait camera rotation; landscape is default.
private let portraitCameraMode = false
/// Set which version of Santa you want to run: physical or virtual
private let runtime = SantaRuntime.physical
/// Set to true to use the new queue-based interaction system
private let useInteractiveMode = true
/// Set to true to show the dashboard in full-screen mode
private let fullScreenDashboard = true

/// The runtime coordinator for Santa figurine control.
/// This replaces the global `santa` StateMachine with a higher-level abstraction.
@MainActor
let coordinator = RuntimeCoordinator(
    runtime: runtime,
    settings: StateMachine.Settings.default.withCameraHorizontalFOV(
        portraitCameraMode ? 60 : 90
    )
)

/// Speech queue configuration and manager (used in interactive mode)
@MainActor
let speechQueueConfig = SpeechQueueConfiguration.default

@MainActor
let speechQueueManager = SpeechQueueManager(config: speechQueueConfig)

/// Audio player for interactive mode
@MainActor
let audioPlayer = AudioPlayer()

/// SantaSpeaker - uses queue-based generation in interactive mode
@MainActor
let speaker = useInteractiveMode
    ? SantaSpeaker(queueManager: speechQueueManager, queueConfig: speechQueueConfig)
    : SantaSpeaker()

/// Interaction coordinator (only used in interactive mode)
@MainActor
var interactionCoordinator: InteractionCoordinator?

/// Dashboard statistics (shared across the app)
@MainActor
let dashboardStats = DashboardStats.shared

@main
struct MinimalApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if coordinator.detectionSource.supportsPreview,
                   let visionSource = coordinator.detectionSource as? VisionDetectionSource {
                    // Physical mode with dashboard
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
                    // Start the coordinator first
                    try await coordinator.start()
                    print("🎅 RoboSanta started in \(coordinator.currentRuntime) mode")
                    
                    // Connect dashboard stats to state machine
                    dashboardStats.connectToStateMachine(coordinator.stateMachine)
                    
                    if useInteractiveMode {
                        // Interactive mode: use queue-based generation and InteractionCoordinator
                        print("🎄 Starting interactive mode with queue-based speech")
                        
                        // Create and start the interaction coordinator
                        interactionCoordinator = InteractionCoordinator(
                            stateMachine: coordinator.stateMachine,
                            audioPlayer: audioPlayer,
                            queueManager: speechQueueManager,
                            config: .default
                        )
                        interactionCoordinator?.start()
                        
                        // Start background speech generation
                        speaker.start()
                    } else {
                        // Legacy mode: direct playback
                        print("🎅 Starting legacy mode with direct playback")
                        speaker.startLegacy()
                    }
                } catch {
                    print("Failed to start coordinator: \(error)")
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
    }
}
