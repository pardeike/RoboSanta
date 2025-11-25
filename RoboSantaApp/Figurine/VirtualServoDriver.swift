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
        logTelemetry("servo.attach", values: ["channel": configuration.channel])
    }
    
    func shutdown() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        logTelemetry("servo.detach", values: ["channel": configuration.channel])
    }
    
    func move(toLogical value: Double) {
        let clamped = configuration.logicalRange.clamped(value)
        targetPosition = clamped
        logTelemetry("servo.command", values: ["target": clamped])
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
        // Simulate servo moving toward target at velocity limit
        let maxDelta = velocity * simulationInterval
        let delta = targetPosition - currentPosition
        
        if abs(delta) <= maxDelta {
            currentPosition = targetPosition
        } else {
            currentPosition += (delta > 0 ? maxDelta : -maxDelta)
        }
        
        // Clamp to logical range
        currentPosition = configuration.logicalRange.clamped(currentPosition)
        
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
