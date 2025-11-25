// VirtualDetectionSource.swift
// Virtual detection source that simulates a person walking past.
// No hardware dependencies; pure Swift simulation.

import Foundation
import Combine
import CoreGraphics

/// Configuration for virtual person simulation.
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

/// Virtual detection source that simulates a person walking past.
final class VirtualDetectionSource: PersonDetectionSource {
    private let config: VirtualPersonConfig
    private let frameSize: CGSize
    private let frameInterval: TimeInterval
    private let detectionSubject = PassthroughSubject<DetectionFrame, Never>()
    private var timer: Timer?
    private var phase: Double = 0
    private var rng: RandomGenerator
    
    var detectionFrames: AnyPublisher<DetectionFrame, Never> {
        detectionSubject.eraseToAnyPublisher()
    }
    
    init(
        config: VirtualPersonConfig = VirtualPersonConfig(),
        frameSize: CGSize = CGSize(width: 1920, height: 1080),
        frameRate: Double = 30
    ) {
        self.config = config
        self.frameSize = frameSize
        self.frameInterval = 1.0 / frameRate
        
        if let seed = config.seed {
            self.rng = RandomGenerator(splitMix: SplitMix64(seed: seed))
        } else {
            self.rng = RandomGenerator()
        }
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            self?.generateFrame()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateFrame() {
        // Update phase for oscillation
        phase += frameInterval * (2 * .pi / config.period)
        if phase > 2 * .pi { phase -= 2 * .pi }
        
        // Calculate horizontal offset (-1...+1)
        let offset = sin(phase) * config.amplitude
        
        // Calculate face size based on distance (closer = larger)
        let baseFaceSize = 0.2  // 20% of frame at 1m
        let faceSize = baseFaceSize / config.distance
        
        // Create detection frame
        let faces: [DetectedFace]
        if rng.nextDouble() < config.presenceProbability {
            let boundingBox = CGRect(
                x: (1.0 + offset) / 2.0 - faceSize / 2.0,
                y: 0.5 - faceSize / 2.0,
                width: faceSize,
                height: faceSize
            )
            faces = [DetectedFace(
                boundingBoxNormalized: boundingBox,
                yawDeg: nil,
                relativeOffset: offset
            )]
        } else {
            faces = []
        }
        
        let frame = DetectionFrame(
            size: frameSize,
            faces: faces,
            previewImage: nil  // No preview image for virtual source
        )
        
        detectionSubject.send(frame)
    }
}

/// Simple seedable RNG for deterministic tests.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

/// A wrapper type to avoid existential overhead when using RandomNumberGenerator.
/// Uses either a seeded SplitMix64 or the system generator based on initialization.
struct RandomGenerator {
    private enum Kind {
        case system(SystemRandomNumberGenerator)
        case splitMix(SplitMix64)
    }
    private var kind: Kind
    
    init() {
        self.kind = .system(SystemRandomNumberGenerator())
    }
    
    init(splitMix: SplitMix64) {
        self.kind = .splitMix(splitMix)
    }
    
    mutating func nextDouble() -> Double {
        switch kind {
        case .system(var gen):
            let value = Double.random(in: 0...1, using: &gen)
            kind = .system(gen)
            return value
        case .splitMix(var gen):
            let value = Double.random(in: 0...1, using: &gen)
            kind = .splitMix(gen)
            return value
        }
    }
}
