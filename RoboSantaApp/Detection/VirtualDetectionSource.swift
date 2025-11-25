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

/// Configuration for virtual detection simulation.
struct VirtualDetectionConfig {
    /// Horizontal field of view of the camera in degrees
    var cameraHorizontalFOV: Double = 90.0
    /// Frame size for detection output
    var frameSize: CGSize = CGSize(width: 1920, height: 1080)
    /// Frame rate for detection updates
    var frameRate: Double = 30.0
    
    static let `default` = VirtualDetectionConfig()
}

/// Virtual detection source that simulates a person walking past.
/// Uses a PersonGenerator to determine person position and calculates the relative
/// offset in the camera frame based on the current camera heading angle.
final class VirtualDetectionSource: PersonDetectionSource {
    private var personGenerator: any PersonGenerator
    private let config: VirtualDetectionConfig
    private let detectionSubject = PassthroughSubject<DetectionFrame, Never>()
    private var timer: Timer?
    private var lastUpdateTime: Date?
    
    /// Current camera heading angle in degrees (body + head rotation).
    /// This should be updated by the rig to reflect the actual camera direction.
    var cameraHeadingDegrees: Double = 0
    
    var detectionFrames: AnyPublisher<DetectionFrame, Never> {
        detectionSubject.eraseToAnyPublisher()
    }
    
    var supportsPreview: Bool { false }
    
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
    
    /// Convenience initializer using the legacy VirtualPersonConfig.
    /// Creates an OscillatingPersonGenerator with equivalent settings.
    convenience init(legacyConfig: VirtualPersonConfig) {
        let oscillatingConfig = OscillatingPersonConfig(
            amplitude: legacyConfig.amplitude * 3.0, // Convert from normalized to meters
            period: legacyConfig.period,
            distance: legacyConfig.distance,
            presenceProbability: legacyConfig.presenceProbability,
            seed: legacyConfig.seed
        )
        let generator = OscillatingPersonGenerator(config: oscillatingConfig)
        self.init(generator: generator, config: VirtualDetectionConfig(
            frameSize: CGSize(width: 1920, height: 1080),
            frameRate: 30.0
        ))
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
        
        // Calculate face position in camera frame
        let faces: [DetectedFace]
        if personState.isPresent {
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
                let baseFaceSize = 0.2  // 20% of frame at 1m
                let faceSize = baseFaceSize / personState.distance
                
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
    }
}

// MARK: - Legacy Configuration (for backward compatibility)

/// Legacy configuration for virtual person simulation.
/// Kept for backward compatibility - new code should use PersonGenerator directly.
struct VirtualPersonConfig {
    /// Amplitude of lateral oscillation (0...1, where 1 = full camera width)
    var amplitude: Double = 0.8
    /// Period of one full oscillation cycle in seconds
    var period: TimeInterval = 6.0
    /// Time to dwell at each end of the path
    var dwellTime: TimeInterval = 1.0
    /// Distance from camera in meters (affects face size)
    var distance: Double = 1.5
    /// Seed for deterministic simulation (nil = random)
    var seed: UInt64? = nil
    /// Probability of person being "present" (0...1)
    var presenceProbability: Double = 0.8
}
