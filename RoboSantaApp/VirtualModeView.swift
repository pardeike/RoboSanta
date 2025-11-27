import SwiftUI
import Combine

/// Placeholder view for virtual mode (no camera preview needed)
struct VirtualModeView: View {
    @ObservedObject var coordinator: RuntimeCoordinator
    @State private var renderer = SantaPreviewRenderer()
    @State private var pose = StateMachine.FigurinePose()
    @State private var zoomScale: Double = 0.5
    @State private var azimuthDegrees: Double = -80
    @State private var isPersonHidden: Bool = false
    private let manualNudgeFallbackStep: Double = 0.25
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
    
    private func togglePersonHidden() -> Bool {
        guard let virtualSource = coordinator.detectionSource as? VirtualDetectionSource else { return false }
        let hidden = virtualSource.togglePersonHidden()
        isPersonHidden = hidden
        renderer.setPersonDimmed(hidden)
        return true
    }
    
    private func nudgeManualPerson(direction: Double) -> Bool {
        guard let virtualSource = coordinator.detectionSource as? VirtualDetectionSource,
              virtualSource.supportsManualControl else { return false }
        let step = virtualSource.manualControlStep ?? manualNudgeFallbackStep
        virtualSource.nudgePerson(by: direction * step)
        return true
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Top half: 3D Santa Preview
                VStack(spacing: 4) {
                    VirtualSantaPreview(zoomScale: $zoomScale, azimuthDegrees: $azimuthDegrees, renderer: renderer)
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
            if let virtualSource = coordinator.detectionSource as? VirtualDetectionSource {
                isPersonHidden = virtualSource.personHidden
                renderer.setPersonDimmed(isPersonHidden)
            }
            updateCamera()
        }
        .onChange(of: zoomScale) { _, _ in updateCamera() }
        .onChange(of: azimuthDegrees) { _, _ in updateCamera() }
        .onReceive(coordinator.poseUpdates.receive(on: RunLoop.main)) { newPose in
            pose = newPose
            renderer.apply(pose: newPose)
            dataBuffer.addDataPoint(pose: newPose)
        }
        .onReceive(personStatesPublisher.receive(on: RunLoop.main)) { state in
            renderer.applyPerson(state: state.isPresent ? state : nil)
        }
        .onKeyPress(.space) {
            if togglePersonHidden() { return .handled }
            return .ignored
        }
        .onKeyPress(.leftArrow) {
            if nudgeManualPerson(direction: -1) { return .handled }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            if nudgeManualPerson(direction: 1) { return .handled }
            return .ignored
        }
    }
}
