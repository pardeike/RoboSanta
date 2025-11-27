// VirtualDetectionSource.swift
// Virtual detection source that simulates a person walking past.
// No hardware dependencies; pure Swift simulation.
//
// The virtual detection source uses the PersonGenerator protocol to simulate
// different person behavior patterns. It calculates the relative offset based
// on the person's world position and the camera's current heading angle.

import Foundation
import Combine
import CoreGraphics
import AppKit

/// Configuration for virtual detection simulation.
struct VirtualDetectionConfig {
    /// Horizontal field of view of the camera in degrees
    var cameraHorizontalFOV: Double = 90.0
    /// Frame size for detection output
    var frameSize: CGSize = CGSize(width: 1920, height: 1080)
    /// Frame rate for detection updates
    var frameRate: Double = 30.0
    /// Base face size as a fraction of frame at 1 meter distance.
    /// Default is 0.2 (20% of frame width at 1 meter).
    var baseFaceSizeAtOneMeter: Double = 0.2
    
    static let `default` = VirtualDetectionConfig()
}

/// Virtual detection source that simulates a person walking past.
/// Uses a PersonGenerator to determine person position and calculates the relative
/// offset in the camera frame based on the current camera heading angle.
final class VirtualDetectionSource: PersonDetectionSource {
    private var personGenerator: any PersonGenerator
    private let config: VirtualDetectionConfig
    private let detectionSubject = PassthroughSubject<DetectionFrame, Never>()
    private let personStateSubject = PassthroughSubject<PersonState, Never>()
    private weak var previewHostLayer: CALayer?
    private let overlayLayer = CALayer()
    private var timer: Timer?
    private var lastUpdateTime: Date?
    
    /// Current camera heading angle in degrees (body + head rotation).
    /// This should be updated by the rig to reflect the actual camera direction.
    var cameraHeadingDegrees: Double = 0
    
    /// When true, forces the person to be hidden regardless of generator state.
    private var isPersonHidden: Bool = false
    
    var detectionFrames: AnyPublisher<DetectionFrame, Never> {
        detectionSubject.eraseToAnyPublisher()
    }

    var personStates: AnyPublisher<PersonState, Never> {
        personStateSubject.eraseToAnyPublisher()
    }
    
    var supportsPreview: Bool { true }
    
    /// Initialize with a custom person generator.
    /// - Parameters:
    ///   - generator: The person generator to use for simulating person behavior.
    ///   - config: Configuration for the detection source.
    init(
        generator: any PersonGenerator = OscillatingPersonGenerator(),
        config: VirtualDetectionConfig = .default
    ) {
        self.personGenerator = generator
        self.config = config
    }

    /// Current hidden state for the simulated person.
    var personHidden: Bool { isPersonHidden }

    /// Toggle whether the simulated person should be hidden.
    /// - Returns: The new hidden state after toggling.
    func togglePersonHidden() -> Bool {
        isPersonHidden.toggle()
        return isPersonHidden
    }

    /// Explicitly set whether the simulated person should be hidden.
    func setPersonHidden(_ hidden: Bool) {
        isPersonHidden = hidden
    }

    /// Whether the current generator supports manual left/right adjustments.
    var supportsManualControl: Bool {
        personGenerator is ManualPersonGenerator
    }

    /// The recommended manual nudge step, if supported.
    var manualControlStep: Double? {
        (personGenerator as? ManualPersonGenerator)?.nudgeStep
    }

    /// Nudge the manual person left/right.
    func nudgePerson(by delta: Double) {
        guard var manual = personGenerator as? ManualPersonGenerator else { return }
        manual.nudge(by: delta)
        personGenerator = manual
    }
    
    func start() {
        lastUpdateTime = Date()
        personGenerator.reset()
        
        let frameInterval = 1.0 / config.frameRate
        timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            self?.generateFrame()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        lastUpdateTime = nil
    }
    
    private func generateFrame() {
        let now = Date()
        let deltaTime = lastUpdateTime.map { now.timeIntervalSince($0) } ?? (1.0 / config.frameRate)
        lastUpdateTime = now
        
        // Update the person generator
        let personState = personGenerator.update(deltaTime: deltaTime)
        personStateSubject.send(personState)
        
        // Calculate face position in camera frame
        // If isPersonHidden is true, we don't detect any faces, but we still publish the person state
        // so the preview can show a dimmed ghost.
        let faces: [DetectedFace]
        if personState.isPresent && !isPersonHidden {
            // Calculate the angle from figurine to person in world space
            let angleToPersonDeg = atan2(personState.horizontalPosition, personState.distance) * 180.0 / .pi
            
            // Calculate relative angle in camera frame
            // Positive angle = person is to the right of camera center
            let relativeAngleDeg = angleToPersonDeg - cameraHeadingDegrees
            
            // Calculate relative offset (-1...+1) based on camera FOV
            // If person is at edge of FOV, offset should be ±1
            let halfFOV = config.cameraHorizontalFOV / 2.0
            let relativeOffset = (relativeAngleDeg / halfFOV).clamped(to: -1.0...1.0)
            
            // Check if person is visible in camera frame
            if abs(relativeAngleDeg) <= halfFOV {
                // Calculate face size based on distance (closer = larger)
                let faceSize = config.baseFaceSizeAtOneMeter / personState.distance
                
                // Calculate bounding box position
                let normalizedX = (1.0 + relativeOffset) / 2.0
                let boundingBox = CGRect(
                    x: normalizedX - faceSize / 2.0,
                    y: 0.5 - faceSize / 2.0,
                    width: faceSize,
                    height: faceSize
                )
                
                faces = [DetectedFace(
                    boundingBoxNormalized: boundingBox,
                    yawDeg: personState.facingAngle,
                    relativeOffset: relativeOffset
                )]
            } else {
                // Person is outside camera FOV
                faces = []
            }
        } else {
            faces = []
        }
        
        let frame = DetectionFrame(
            size: config.frameSize,
            faces: faces,
            previewImage: nil  // No preview image for virtual source
        )
        
        detectionSubject.send(frame)
        renderPreview(for: frame)
    }

    private func renderPreview(for frame: DetectionFrame) {
        guard let hostLayer = previewHostLayer else { return }
        DispatchQueue.main.async {
            self.overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.overlayLayer.frame = hostLayer.bounds
            let width = hostLayer.bounds.width
            let height = hostLayer.bounds.height

            for face in frame.faces {
                let rect = CGRect(
                    x: face.boundingBoxNormalized.minX * width,
                    y: face.boundingBoxNormalized.minY * height,
                    width: face.boundingBoxNormalized.width * width,
                    height: face.boundingBoxNormalized.height * height
                )
                let shape = CAShapeLayer()
                shape.frame = rect
                shape.path = CGPath(rect: CGRect(origin: .zero, size: rect.size), transform: nil)
                shape.fillColor = NSColor.white.withAlphaComponent(0.12).cgColor
                shape.strokeColor = NSColor.white.cgColor
                shape.lineWidth = 2.0
                self.overlayLayer.addSublayer(shape)
            }
        }
    }
}

extension VirtualDetectionSource: DetectionPreviewProviding {
    func attachPreview(to layer: CALayer) {
        previewHostLayer = layer
        DispatchQueue.main.async {
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            layer.backgroundColor = NSColor.black.cgColor
            self.overlayLayer.frame = layer.bounds
            self.overlayLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.addSublayer(self.overlayLayer)
        }
    }
}
