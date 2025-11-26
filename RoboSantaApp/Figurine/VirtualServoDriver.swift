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
    /// Factor to divide large velocity values by to produce realistic movement speeds.
    private static let velocityScalingFactor: Double = 100.0
    
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
        // The velocity values passed from settings (e.g., 200, 500 for left hand)
        // are in Phidget's internal units. Real Phidget hardware clamps these to
        // its physical limits. For example, a typical RC servo has velocity limits
        // around 0.1-4.0 in normalized 0-1 space (meaning it takes 0.25-10 seconds
        // to traverse the full range).
        //
        // For virtual mode, we simulate realistic servo behavior by interpreting
        // the velocity as a fraction of the logical range per second, capped to
        // prevent instant movement. A velocity of 1.0 means 1 full range per second.
        //
        // Since left hand has range 0-1 and settings use values like 200/500,
        // we need to scale appropriately. Phidget velocity limits are typically
        // around 1-4 for normalized servos. We simulate by dividing large velocities.
        //
        let effectiveVelocity: Double
        if velocity > Self.velocityScalingThreshold {
            // Large velocity values (e.g., 200, 500) are in Phidget raw units.
            // Scale down to produce realistic movement speeds.
            // A velocity of 200 becomes 2.0 (full range in 0.5s).
            effectiveVelocity = velocity / Self.velocityScalingFactor
        } else {
            // Small velocity values are already in normalized units
            effectiveVelocity = velocity
        }
        
        let maxDelta = effectiveVelocity * simulationInterval
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
