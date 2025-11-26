// VirtualServoDriver.swift
// Virtual servo driver that simulates position over time.
// No hardware dependencies; pure Swift simulation.

import Foundation

/// Virtual servo driver that simulates position over time.
/// No hardware dependencies; pure Swift simulation.
final class VirtualServoDriver: ServoDriver {
    private let configuration: StateMachine.ServoChannelConfiguration
    private var currentPosition: Double
    private var targetPosition: Double
    private var velocity: Double
    private var positionObserver: ((Double) -> Void)?
    private var telemetryLogger: ((String, [String: CustomStringConvertible]) -> Void)?
    private var simulationTimer: Timer?
    private let simulationInterval: TimeInterval = 0.02  // 50 Hz, matches StateMachine loop
    
    /// Velocity values above this threshold are considered Phidget raw units and need scaling.
    private static let velocityScalingThreshold: Double = 10.0
    /// Factor to divide large velocity values by to convert from Phidget units to normalized velocity.
    /// A velocity of 200 becomes 1.0 (1 full logical range per second), so a servo moves its
    /// entire range in 1 second. velocity=500 becomes 2.5 range/sec (full range in 0.4s).
    /// This produces realistic movement times similar to physical RC servos under load.
    private static let velocityScalingFactor: Double = 200.0
    
    init(configuration: StateMachine.ServoChannelConfiguration) {
        self.configuration = configuration
        self.currentPosition = configuration.homePosition
        self.targetPosition = configuration.homePosition
        self.velocity = configuration.velocityLimit ?? 100
    }
    
    func open(timeout: TimeInterval) throws {
        // Start simulation loop
        simulationTimer = Timer.scheduledTimer(withTimeInterval: simulationInterval, repeats: true) { [weak self] _ in
            self?.updateSimulation()
        }
        if let timer = simulationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        // Seed the observer with the initial position so the state machine has a measured value.
        positionObserver?(currentPosition)
        logTelemetry("servo.attach", values: ["channel": configuration.channel])
    }
    
    func shutdown() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        logTelemetry("servo.detach", values: ["channel": configuration.channel])
    }
    
    func move(toLogical value: Double) {
        let clampedValue = configuration.logicalRange.clamp(value)
        targetPosition = clampedValue
        logTelemetry("servo.command", values: ["target": clampedValue])
    }
    
    func setVelocity(_ velocity: Double) {
        self.velocity = velocity
        logTelemetry("servo.velocitySet", values: ["velocity": velocity])
    }
    
    func setPositionObserver(_ observer: @escaping (Double) -> Void) {
        positionObserver = observer
    }
    
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void) {
        telemetryLogger = logger
    }
    
    private func updateSimulation() {
        // Simulate servo moving toward target at velocity limit.
        //
        // VELOCITY MODEL:
        // Phidget RC servo velocity is specified in normalized position units per second,
        // where the servo position range is always 0...1 (normalized). The PhidgetServoDriver
        // maps logical positions (e.g., -30...30 degrees for head, 0...1 for hand) to this
        // 0...1 range before commanding the servo.
        //
        // To match physical behavior, we interpret the velocity as "fraction of logical
        // range per second". This means:
        //   - velocity=1.0 → servo can traverse its full logical range in 1 second
        //   - velocity=2.0 → servo can traverse its full logical range in 0.5 seconds
        //
        // The settings use large values like 200, 500 which are scaled down to get
        // realistic speeds. The scaling factor of 200 means:
        //   - velocity=200 → 1.0 range/sec (full range in 1 second)
        //   - velocity=500 → 2.5 range/sec (full range in 0.4 seconds)
        //
        // The key insight is that maxDelta must be in LOGICAL units (same as currentPosition),
        // so we multiply the normalized velocity by the logical range span.
        //
        let normalizedVelocity: Double
        if velocity > Self.velocityScalingThreshold {
            // Large velocity values (e.g., 200, 500) are in Phidget raw units.
            // Scale down to produce realistic movement speeds.
            normalizedVelocity = velocity / Self.velocityScalingFactor
        } else {
            // Small velocity values are already in normalized units
            normalizedVelocity = velocity
        }
        
        // Convert normalized velocity (range/sec) to logical velocity (logical units/sec)
        let logicalRangeSpan = configuration.logicalRange.span
        let logicalVelocity = normalizedVelocity * logicalRangeSpan
        
        let maxDelta = logicalVelocity * simulationInterval
        let delta = targetPosition - currentPosition
        
        if abs(delta) <= maxDelta {
            currentPosition = targetPosition
        } else {
            currentPosition += (delta > 0 ? maxDelta : -maxDelta)
        }
        
        // Clamp to logical range
        currentPosition = configuration.logicalRange.clamp(currentPosition)
        
        // Notify observer (matches hardware callback pattern)
        positionObserver?(currentPosition)
        logTelemetry("servo.position", values: ["value": currentPosition])
    }
    
    private func logTelemetry(_ event: String, values: [String: CustomStringConvertible] = [:]) {
        var merged = values
        merged["servo"] = configuration.name
        telemetryLogger?(event, merged)
    }
}

/// Factory for virtual servo drivers.
struct VirtualServoDriverFactory: ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver {
        VirtualServoDriver(configuration: config)
    }
}
