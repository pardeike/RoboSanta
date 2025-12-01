import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var visionSource: VisionDetectionSource

    var body: some View {
        DashboardView(coordinator: coordinator, deepSleepController: deepSleepController)
            .environmentObject(visionSource)
    }
}
