// PhidgetServoDriver.swift
// Physical servo driver wrapping Phidget RCServo.
// This is a direct extraction of the existing ServoChannel class.

import Foundation

/// Physical servo driver wrapping Phidget RCServo.
final class PhidgetServoDriver: ServoDriver {
    private let configuration: StateMachine.ServoChannelConfiguration
    private let servo: RCServo = RCServo()
    private var attached = false
    private var currentNormalized: Double?
    private var isOpen = false
    private var telemetryLogger: ((String, [String: CustomStringConvertible]) -> Void)?
    private var positionObserver: ((Double) -> Void)?
    
    init(configuration: StateMachine.ServoChannelConfiguration) {
        self.configuration = configuration
        setupHandlers()
    }
    
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void) {
        telemetryLogger = logger
    }
    
    func setPositionObserver(_ observer: @escaping (Double) -> Void) {
        positionObserver = observer
    }
    
    func open(timeout: TimeInterval) throws {
        guard !isOpen else { return }
        try configure("setChannel") { try servo.setChannel(configuration.channel) }
        try configure("setIsHubPortDevice") { try servo.setIsHubPortDevice(false) }
        try configure("setIsLocal") { try servo.setIsLocal(true) }
        try configure("open") { try servo.open() }
        do {
            try waitForAttachment(timeout: timeout)
            try configure("setMinPosition") { try servo.setMinPosition(0) }
            try configure("setMaxPosition") { try servo.setMaxPosition(1) }
            let minPulseLimit = try? servo.getMinPulseWidthLimit()
            let maxPulseLimit = try? servo.getMaxPulseWidthLimit()
            let requestedMinPulse = clamp(configuration.pulseRange.lowerBound, min: minPulseLimit, max: maxPulseLimit)
            var requestedMaxPulse = clamp(configuration.pulseRange.upperBound, min: minPulseLimit, max: maxPulseLimit)
            if requestedMaxPulse <= requestedMinPulse { requestedMaxPulse = requestedMinPulse + 1 }
            try configure("setMinPulseWidth") { try servo.setMinPulseWidth(requestedMinPulse) }
            try configure("setMaxPulseWidth") { try servo.setMaxPulseWidth(requestedMaxPulse) }
            try configure("setSpeedRampingState") { try servo.setSpeedRampingState(true) }
            if let velocity = configuration.velocityLimit {
                let clampedVelocity = clamp(velocity, min: try? servo.getMinVelocityLimit(), max: try? servo.getMaxVelocityLimit())
                try configure("setVelocityLimit") { try servo.setVelocityLimit(clampedVelocity) }
            }
            if let voltage = configuration.voltage {
                try configure("setVoltage") { try servo.setVoltage(voltage) }
            }
            // Move to the home position before engaging so the controller is configured.
            move(toLogical: configuration.homePosition, force: true)
            try configure("setEngaged") { try servo.setEngaged(true) }
            isOpen = true
        } catch {
            perform("setEngaged(false)") { try servo.setEngaged(false) }
            perform("close") { try servo.close() }
            attached = false
            throw error
        }
    }
    
    func move(toLogical value: Double) { move(toLogical: value, force: false) }
    
    func setVelocity(_ velocity: Double) {
        guard isOpen else { return }
        let clampedVelocity = clamp(velocity, min: try? servo.getMinVelocityLimit(), max: try? servo.getMaxVelocityLimit())
        perform("setVelocityLimit") { try servo.setVelocityLimit(clampedVelocity) }
        logTelemetry("servo.velocitySet", values: ["velocity": clampedVelocity])
    }
    
    func shutdown() {
        guard isOpen else { return }
        isOpen = false
        perform("setEngaged(false)") { try servo.setEngaged(false) }
        perform("close") { try servo.close() }
        attached = false
    }
    
    private func move(toLogical value: Double, force: Bool) {
        guard isOpen || force else { return }
        let normalized = normalizedValue(for: value)
        guard force || currentNormalized.map({ abs($0 - normalized) > 0.001 }) ?? true else { return }
        currentNormalized = normalized
        perform("setTargetPosition") { try servo.setTargetPosition(normalized) }
        logTelemetry("servo.command", values: ["target": normalized])
    }
    
    private func normalizedValue(for logical: Double) -> Double {
        let range = configuration.logicalRange
        let clamped = range.clamp(logical)
        let normalized = (clamped - range.lowerBound) / range.span
        switch configuration.orientation {
        case .normal:   return normalized
        case .reversed: return 1 - normalized
        }
    }

    private func logicalValue(forServoPosition normalized: Double) -> Double {
        let clamped = normalized.clamped(to: 0...1)
        let logicalNormalized: Double
        switch configuration.orientation {
        case .normal:
            logicalNormalized = clamped
        case .reversed:
            logicalNormalized = 1 - clamped
        }
        return configuration.logicalRange.lowerBound + logicalNormalized * configuration.logicalRange.span
    }
    
    private func waitForAttachment(timeout: TimeInterval) throws {
        let start = Date()
        while !attached {
            if Date().timeIntervalSince(start) > timeout {
                throw StateMachine.FigurineError.attachmentTimeout(channel: configuration.channel)
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    private func setupHandlers() {
        _ = servo.error.addHandler { [weak self] _, data in
            guard let self else { return }
            self.logTelemetry("servo.error", values: ["code": data.code.rawValue, "description": data.description])
        }
        _ = servo.attach.addHandler { [weak self] sender in
            guard let self else { return }
            self.attached = true
            let channel = (try? sender.getChannel()) ?? -1
            self.logTelemetry("servo.attach", values: ["channel": channel])
        }
        _ = servo.detach.addHandler { [weak self] sender in
            guard let self else { return }
            self.attached = false
            let channel = (try? sender.getChannel()) ?? -1
            self.logTelemetry("servo.detach", values: ["channel": channel])
        }
        _ = servo.velocityChange.addHandler { [weak self] _, velocity in
            self?.logTelemetry("servo.velocity", values: ["value": velocity])
        }
        _ = servo.positionChange.addHandler { [weak self] _, position in
            guard let self else { return }
            self.positionObserver?(self.logicalValue(forServoPosition: position))
            self.logTelemetry("servo.position", values: ["value": position])
        }
        _ = servo.targetPositionReached.addHandler { [weak self] _, position in
            self?.logTelemetry("servo.targetReached", values: ["value": position])
        }
    }

    private func configure(_ step: String, _ action: () throws -> Void) throws {
        do { try action() }
        catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            throw err
        }
        catch {
            logTelemetry("servo.error", values: ["step": step, "description": "\(error)"])
            throw error
        }
    }
    
    private func perform(_ step: String, _ action: () throws -> Void) {
        do { try action() }
        catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            logTelemetry("servo.error", values: ["step": step, "code": err.errorCode.rawValue, "description": err.description])
        }
        catch {
            logTelemetry("servo.error", values: ["step": step, "description": "\(error)"])
        }
    }
    
    private func clamp(_ value: Double, min: Double?, max: Double?) -> Double {
        var lower = min
        var upper = max
        if let l = lower, let u = upper, l > u { lower = u; upper = l }
        var clamped = value
        if let lower { clamped = Swift.max(clamped, lower) }
        if let upper { clamped = Swift.min(clamped, upper) }
        return clamped
    }
    
    private func logTelemetry(_ event: String, values: [String: CustomStringConvertible] = [:]) {
        var merged = values
        merged["servo"] = configuration.name
        telemetryLogger?(event, merged)
    }
}

/// Factory for physical servo drivers.
struct PhidgetServoDriverFactory: ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver {
        PhidgetServoDriver(configuration: config)
    }
}

// MARK: - Private extensions (moved from StateMachine.swift)

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension ClosedRange where Bound == Double {
    var span: Double { upperBound - lowerBound }
    func clamp(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
