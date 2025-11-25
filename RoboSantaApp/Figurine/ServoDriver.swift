// ServoDriver.swift
// Protocol for servo hardware abstraction.

import Foundation

/// Protocol for servo hardware abstraction.
/// Physical implementation wraps Phidget RCServo; virtual implementation simulates position over time.
protocol ServoDriver: AnyObject {
    /// Connect to the servo hardware (physical) or initialize simulation (virtual).
    func open(timeout: TimeInterval) throws
    
    /// Disconnect and release resources.
    func shutdown()
    
    /// Command the servo to move to a logical position (e.g., degrees or normalized 0..1).
    func move(toLogical value: Double)
    
    /// Set the velocity limit for subsequent moves.
    func setVelocity(_ velocity: Double)
    
    /// Register a callback for position updates.
    /// For physical servos, invoked when hardware reports position changes.
    /// For virtual servos, invoked at ~50Hz during simulation.
    func setPositionObserver(_ observer: @escaping (Double) -> Void)
    
    /// Register a callback for telemetry logging.
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void)
}

/// Factory that creates ServoDrivers for the figurine.
protocol ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver
}
