import SwiftUI

/// Set to true to keep the legacy 90° portrait camera rotation; landscape is default.
private let portraitCameraMode = false
/// Set which version of Santa you want to run: physical or virtual
private let runtime = SantaRuntime.physical

/// The runtime coordinator for Santa figurine control.
/// This replaces the global `santa` StateMachine with a higher-level abstraction.
@MainActor
let coordinator = RuntimeCoordinator(
    runtime: runtime,
    settings: StateMachine.Settings.default.withCameraHorizontalFOV(
        portraitCameraMode ? 60 : 90
    )
)

@MainActor
let speaker = SantaSpeaker()

@main
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
                    speaker.start()
                    try await coordinator.start()
                    print("🎅 RoboSanta started in \(coordinator.currentRuntime) mode")
                } catch {
                    print("Failed to start coordinator: \(error)")
                }
            }
        }
    }
}
