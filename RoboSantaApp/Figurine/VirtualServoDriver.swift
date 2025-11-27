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
    private var currentVelocity: Double = 0  // Current instantaneous velocity for ramping
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
    /// Maximum normalized velocity (range/sec) to simulate physical servo limits.
    /// Real RC servos under load typically can't exceed ~2-4 range/sec due to motor torque limits.
    /// This caps the virtual servo to ~1.5 range/sec (full range in ~0.67 seconds), matching
    /// realistic servo behavior and preventing unrealistically fast movements like instant waves.
    private static let maxNormalizedVelocity: Double = 1.5
    /// Acceleration rate for speed ramping (range/sec²).
    /// Controls how quickly the servo ramps up to target velocity.
    /// Higher values = snappier response; lower values = smoother, more gradual acceleration.
    private static let accelerationRate: Double = 8.0
    /// Deceleration distance threshold as a fraction of movement.
    /// When remaining distance is less than this fraction of total travel, start decelerating.
    /// E.g., 0.3 means start slowing down when 30% of the way remains.
    private static let decelerationThreshold: Double = 0.25
    /// Minimum velocity during deceleration (prevents stalling near target).
    private static let minDecelerationVelocity: Double = 0.15
    /// Position tolerance for considering servo at target (logical units).
    private static let positionTolerance: Double = 0.0001
    /// Deceleration is faster than acceleration for more responsive stopping.
    /// Real servos often decelerate faster due to mechanical braking effects.
    private static let decelerationMultiplier: Double = 1.5
    
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
        // Dispatch to main thread for consistent state access.
        // The timer is scheduled on main thread, so invalidating it there is correct.
        if Thread.isMainThread {
            performShutdown()
        } else {
            DispatchQueue.main.sync {
                performShutdown()
            }
        }
    }
    
    private func performShutdown() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        logTelemetry("servo.detach", values: ["channel": configuration.channel])
    }
    
    func move(toLogical value: Double) {
        let clampedValue = configuration.logicalRange.clamp(value)
        // Dispatch to main thread to ensure thread-safe access to servo state.
        // The state machine calls this from its workerQueue, but the simulation
        // timer runs on the main thread. Without synchronization, targetPosition
        // updates might not be visible to the simulation loop due to CPU caching,
        // causing the servo to appear "stuck" at its previous position.
        if Thread.isMainThread {
            applyMove(clampedValue)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.applyMove(clampedValue)
            }
        }
    }
    
    private func applyMove(_ clampedValue: Double) {
        // If direction is changing while in motion, reset velocity to simulate real servo
        // behavior where the motor must stop before reversing.
        // Only check when servo is actually moving (currentVelocity > 0) to avoid
        // issues when starting from rest.
        if currentVelocity > 0 {
            let currentDirection = targetPosition - currentPosition
            let newDirection = clampedValue - currentPosition
            if currentDirection * newDirection < 0 {
                // Direction change detected while moving - reset velocity
                currentVelocity = 0
            }
        }
        targetPosition = clampedValue
        logTelemetry("servo.command", values: ["target": clampedValue])
    }
    
    func setVelocity(_ velocity: Double) {
        // Dispatch to main thread to ensure thread-safe access to servo state.
        // See move(toLogical:) for rationale.
        if Thread.isMainThread {
            applyVelocity(velocity)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.applyVelocity(velocity)
            }
        }
    }
    
    private func applyVelocity(_ velocity: Double) {
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
        // Simulate servo moving toward target with speed ramping (acceleration/deceleration).
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
        // However, real servos have physical velocity limits due to motor torque constraints.
        // The PhidgetServoDriver clamps velocity to hardware limits. We simulate this by
        // capping the normalized velocity to maxNormalizedVelocity (~1.5 range/sec).
        //
        // SPEED RAMPING:
        // Real servos (with setSpeedRampingState(true)) accelerate from rest and decelerate
        // when approaching the target. We simulate this by:
        // 1. Ramping up currentVelocity toward targetVelocity using accelerationRate
        // 2. Ramping down when close to target (within decelerationThreshold of remaining distance)
        //
        // The key insight is that maxDelta must be in LOGICAL units (same as currentPosition),
        // so we multiply the normalized velocity by the logical range span.
        //
        var normalizedTargetVelocity: Double
        if velocity > Self.velocityScalingThreshold {
            // Large velocity values (e.g., 200, 500) are in Phidget raw units.
            // Scale down to produce realistic movement speeds.
            normalizedTargetVelocity = velocity / Self.velocityScalingFactor
        } else {
            // Small velocity values are already in normalized units
            normalizedTargetVelocity = velocity
        }
        
        // Cap velocity to simulate physical servo limits
        normalizedTargetVelocity = min(normalizedTargetVelocity, Self.maxNormalizedVelocity)
        
        // Convert normalized velocity (range/sec) to logical velocity (logical units/sec)
        let logicalRangeSpan = configuration.logicalRange.span
        let targetLogicalVelocity = normalizedTargetVelocity * logicalRangeSpan
        
        let delta = targetPosition - currentPosition
        let remainingDistance = abs(delta)
        
        // If we're at the target, stop
        guard remainingDistance > Self.positionTolerance else {
            currentPosition = targetPosition
            currentVelocity = 0
            positionObserver?(currentPosition)
            logTelemetry("servo.position", values: ["value": currentPosition])
            return
        }
        
        // Calculate deceleration zone: slow down when within this distance of target
        // Use a fraction of the logical range for consistent feel across different servo ranges
        let decelerationDistance = logicalRangeSpan * Self.decelerationThreshold
        
        // Determine desired velocity based on position
        let desiredVelocity: Double
        if remainingDistance < decelerationDistance {
            // In deceleration zone: scale velocity based on remaining distance
            // Use sqrt for smoother deceleration curve (feels more natural than linear)
            let decelerationFactor = sqrt(remainingDistance / decelerationDistance)
            let minVelocity = Self.minDecelerationVelocity * logicalRangeSpan
            desiredVelocity = max(minVelocity, targetLogicalVelocity * decelerationFactor)
        } else {
            // Cruising: aim for target velocity
            desiredVelocity = targetLogicalVelocity
        }
        
        // Apply acceleration/deceleration ramping to current velocity
        let accelerationDelta = Self.accelerationRate * logicalRangeSpan * simulationInterval
        if currentVelocity < desiredVelocity {
            // Accelerating
            currentVelocity = min(desiredVelocity, currentVelocity + accelerationDelta)
        } else if currentVelocity > desiredVelocity {
            // Decelerating (faster than acceleration for more responsive stopping)
            currentVelocity = max(desiredVelocity, currentVelocity - accelerationDelta * Self.decelerationMultiplier)
        }
        
        // Calculate movement for this tick
        let maxDelta = currentVelocity * simulationInterval
        
        if remainingDistance <= maxDelta {
            currentPosition = targetPosition
            currentVelocity = 0
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
