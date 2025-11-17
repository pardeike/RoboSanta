import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var camera: CameraManager

    @State private var detectFaces = true
    @State private var detectPeople = true
    @State private var bias: Float = 0.0
    @State private var lowLightBoost = true
    @State private var targetFPS: Double = 30

    var body: some View {
        VStack(spacing: 8) {
            CameraPreview()
                .environmentObject(camera)
        }
    }
}
