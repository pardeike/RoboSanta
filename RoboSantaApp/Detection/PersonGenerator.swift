// PersonGenerator.swift
// Protocol for generating virtual person positions.
// Allows developers to plug in multiple person generators that simulate different interaction patterns.

import Foundation
import CoreGraphics

/// Represents the state of a virtual person in the simulation space.
/// The position is in world coordinates relative to the figurine.
struct PersonState {
    /// Whether the person is currently present/visible
    let isPresent: Bool
    /// Horizontal position relative to figurine center (in meters, positive = right)
    let horizontalPosition: Double
    /// Distance from the figurine (in meters)
    let distance: Double
    /// Optional facing angle (degrees from straight-on, positive = facing right)
    let facingAngle: Double?
    
    /// A person who is not present/visible.
    static let absent = PersonState(isPresent: false, horizontalPosition: 0, distance: 1.5, facingAngle: nil)
}

/// Protocol for generating virtual person positions.
/// Implementations can simulate different interaction patterns:
/// - Simple oscillation (back and forth)
/// - Walk through (enter, pass, exit)
/// - Random wandering
/// - Scenario-based interactions
protocol PersonGenerator {
    /// Update the simulation and return the current person state.
    /// - Parameter deltaTime: Time elapsed since last update in seconds.
    /// - Returns: The current state of the virtual person.
    mutating func update(deltaTime: TimeInterval) -> PersonState
    
    /// Reset the generator to its initial state.
    mutating func reset()
}

// MARK: - Oscillating Person Generator

/// Configuration for the oscillating person generator.
struct OscillatingPersonConfig {
    /// Amplitude of lateral oscillation in meters (default 2.4m = 0.8 * 3m walk width)
    var amplitude: Double = 2.4
    /// Period of one full oscillation cycle in seconds
    var period: TimeInterval = 6.0
    /// Distance from figurine in meters
    var distance: Double = 2.0
    /// Probability of person being visible per frame (0...1)
    var presenceProbability: Double = 0.8
    /// Seed for deterministic simulation (nil = random)
    var seed: UInt64? = nil
    
    static let `default` = OscillatingPersonConfig()
}

/// A simple person generator that oscillates back and forth.
/// This is the default generator that replicates the existing VirtualSantaPreview behavior.
struct OscillatingPersonGenerator: PersonGenerator {
    private var config: OscillatingPersonConfig
    private var phase: Double = 0
    private var rng: RandomGenerator
    
    init(config: OscillatingPersonConfig = .default) {
        self.config = config
        if let seed = config.seed {
            self.rng = RandomGenerator(splitMix: SplitMix64(seed: seed))
        } else {
            self.rng = RandomGenerator()
        }
    }
    
    mutating func update(deltaTime: TimeInterval) -> PersonState {
        // Update phase for oscillation
        phase += deltaTime * (2 * .pi / config.period)
        if phase > 2 * .pi { phase -= 2 * .pi }
        
        // Calculate horizontal position (in meters)
        let horizontalPosition = sin(phase) * config.amplitude
        
        // Determine visibility
        let isPresent = rng.nextDouble() < config.presenceProbability
        
        return PersonState(
            isPresent: isPresent,
            horizontalPosition: horizontalPosition,
            distance: config.distance,
            facingAngle: nil
        )
    }
    
    mutating func reset() {
        phase = 0
        if let seed = config.seed {
            rng = RandomGenerator(splitMix: SplitMix64(seed: seed))
        }
    }
}

// MARK: - Walk Through Person Generator

/// Configuration for the walk-through person generator.
struct WalkThroughPersonConfig {
    /// Starting horizontal position in meters (positive = right)
    var startPosition: Double = -3.0
    /// Ending horizontal position in meters
    var endPosition: Double = 3.0
    /// Walking speed in meters per second
    var walkSpeed: Double = 1.0
    /// Time to pause at start before walking
    var startDelay: TimeInterval = 0.5
    /// Distance from figurine in meters
    var distance: Double = 2.0
    /// Whether to loop back after completing
    var loopEnabled: Bool = true
    /// Delay before restarting when looping
    var loopDelay: TimeInterval = 2.0
    
    static let `default` = WalkThroughPersonConfig()
}

/// A person generator that simulates someone walking through the scene.
/// The person enters from one side, walks across, and exits on the other side.
struct WalkThroughPersonGenerator: PersonGenerator {
    private let originalConfig: WalkThroughPersonConfig
    private var currentStartPosition: Double
    private var currentEndPosition: Double
    private var currentPosition: Double
    private var elapsedTime: TimeInterval = 0
    private var state: WalkState = .waiting
    
    private enum WalkState {
        case waiting
        case walking
        case exited
        case waitingToLoop
    }
    
    init(config: WalkThroughPersonConfig = .default) {
        self.originalConfig = config
        self.currentStartPosition = config.startPosition
        self.currentEndPosition = config.endPosition
        self.currentPosition = config.startPosition
    }
    
    mutating func update(deltaTime: TimeInterval) -> PersonState {
        elapsedTime += deltaTime
        
        switch state {
        case .waiting:
            if elapsedTime >= originalConfig.startDelay {
                state = .walking
            }
            return PersonState.absent
            
        case .walking:
            // Move toward end position
            let direction = currentEndPosition > currentPosition ? 1.0 : -1.0
            currentPosition += direction * originalConfig.walkSpeed * deltaTime
            
            // Check if reached destination
            if (direction > 0 && currentPosition >= currentEndPosition) ||
               (direction < 0 && currentPosition <= currentEndPosition) {
                currentPosition = currentEndPosition
                if originalConfig.loopEnabled {
                    state = .waitingToLoop
                    elapsedTime = 0
                } else {
                    state = .exited
                }
            }
            
            return PersonState(
                isPresent: true,
                horizontalPosition: currentPosition,
                distance: originalConfig.distance,
                facingAngle: nil
            )
            
        case .exited:
            return PersonState.absent
            
        case .waitingToLoop:
            if elapsedTime >= originalConfig.loopDelay {
                // Swap start and end for reverse walk (using instance variables)
                swap(&currentStartPosition, &currentEndPosition)
                currentPosition = currentStartPosition
                state = .walking
            }
            return PersonState.absent
        }
    }
    
    mutating func reset() {
        currentStartPosition = originalConfig.startPosition
        currentEndPosition = originalConfig.endPosition
        currentPosition = originalConfig.startPosition
        elapsedTime = 0
        state = .waiting
    }
}

// MARK: - Random Wandering Person Generator

/// Configuration for the random wandering person generator.
struct RandomWanderingPersonConfig {
    /// Maximum horizontal range in meters (symmetric around center)
    var horizontalRange: Double = 2.5
    /// Average time to dwell at a position before moving
    var averageDwellTime: TimeInterval = 2.0
    /// Average walking speed in meters per second
    var averageWalkSpeed: Double = 0.8
    /// Distance range from figurine in meters
    var distanceRange: ClosedRange<Double> = 1.5...2.5
    /// Probability of temporarily disappearing (0...1)
    var disappearProbability: Double = 0.05
    /// Average duration of disappearance
    var averageDisappearDuration: TimeInterval = 1.0
    /// Seed for deterministic simulation (nil = random)
    var seed: UInt64? = nil
    
    static let `default` = RandomWanderingPersonConfig()
}

/// A person generator that simulates someone wandering around randomly.
/// The person moves to random positions, pauses, and occasionally disappears.
struct RandomWanderingPersonGenerator: PersonGenerator {
    private var config: RandomWanderingPersonConfig
    private var currentPosition: Double = 0
    private var currentDistance: Double
    private var targetPosition: Double = 0
    private var targetDistance: Double
    private var dwellTimeRemaining: TimeInterval = 0
    private var disappearTimeRemaining: TimeInterval = 0
    private var isMoving = false
    private var rng: RandomGenerator
    
    init(config: RandomWanderingPersonConfig = .default) {
        self.config = config
        self.currentDistance = (config.distanceRange.lowerBound + config.distanceRange.upperBound) / 2
        self.targetDistance = currentDistance
        if let seed = config.seed {
            self.rng = RandomGenerator(splitMix: SplitMix64(seed: seed))
        } else {
            self.rng = RandomGenerator()
        }
        pickNewTarget()
    }
    
    mutating func update(deltaTime: TimeInterval) -> PersonState {
        // Handle disappearance
        if disappearTimeRemaining > 0 {
            disappearTimeRemaining -= deltaTime
            return PersonState.absent
        }
        
        // Random chance to disappear
        if rng.nextDouble() < config.disappearProbability * deltaTime {
            disappearTimeRemaining = config.averageDisappearDuration * (0.5 + rng.nextDouble())
            return PersonState.absent
        }
        
        // Handle dwelling
        if dwellTimeRemaining > 0 {
            dwellTimeRemaining -= deltaTime
            return PersonState(
                isPresent: true,
                horizontalPosition: currentPosition,
                distance: currentDistance,
                facingAngle: nil
            )
        }
        
        // Move toward target
        if isMoving {
            let speed = config.averageWalkSpeed
            
            // Move horizontal position
            let hDelta = targetPosition - currentPosition
            if abs(hDelta) < speed * deltaTime {
                currentPosition = targetPosition
            } else {
                currentPosition += (hDelta > 0 ? 1 : -1) * speed * deltaTime
            }
            
            // Move distance
            let dDelta = targetDistance - currentDistance
            if abs(dDelta) < speed * 0.5 * deltaTime {
                currentDistance = targetDistance
            } else {
                currentDistance += (dDelta > 0 ? 1 : -1) * speed * 0.5 * deltaTime
            }
            
            // Check if arrived
            if abs(currentPosition - targetPosition) < 0.01 && abs(currentDistance - targetDistance) < 0.01 {
                isMoving = false
                dwellTimeRemaining = config.averageDwellTime * (0.5 + rng.nextDouble())
                pickNewTarget()
            }
        } else {
            // Start moving to target
            isMoving = true
        }
        
        return PersonState(
            isPresent: true,
            horizontalPosition: currentPosition,
            distance: currentDistance,
            facingAngle: nil
        )
    }
    
    mutating func reset() {
        currentPosition = 0
        currentDistance = (config.distanceRange.lowerBound + config.distanceRange.upperBound) / 2
        targetPosition = 0
        targetDistance = currentDistance
        dwellTimeRemaining = 0
        disappearTimeRemaining = 0
        isMoving = false
        if let seed = config.seed {
            rng = RandomGenerator(splitMix: SplitMix64(seed: seed))
        }
        pickNewTarget()
    }
    
    private mutating func pickNewTarget() {
        targetPosition = (rng.nextDouble() * 2 - 1) * config.horizontalRange
        let range = config.distanceRange
        targetDistance = range.lowerBound + rng.nextDouble() * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Random Number Generator Utilities

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
