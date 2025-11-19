import Foundation
import Dispatch

/// Drives the physical figurine by coordinating the four Phidget RC servos.
/// A lightweight internal loop keeps gestures like waves or idle sweeps alive
/// even when nothing else is happening in the app. Feed it `Event`s from the
/// outside world to influence Santa's pose.
final class StateMachine {
    enum Event: Equatable {
        case idle
        case aimCamera(Double) // degrees relative to Santa's forward direction
        case clearTarget
        case setLeftHand(LeftHandGesture)
        case setRightHand(RightHandGesture)
        case setIdleBehavior(IdleBehavior)
    }
    
    enum LeftHandGesture: Equatable {
        case down
        case up
        case wave(amplitude: Double = 0.12, speed: Double = 1.6)
    }
    
    enum RightHandGesture: Equatable {
        case down
        case point
        case emphasise
    }
    
    enum IdleBehavior: Equatable {
        case none
        case sweep(range: ClosedRange<Double>, period: TimeInterval)
    }
    
    struct FigurinePose {
        var bodyAngle: Double
        var headAngle: Double
        var leftHand: Double
        var rightHand: Double
        var cameraHeading: Double { bodyAngle + headAngle }
    }
    
    struct FigurineConfiguration {
        let leftHand: ServoChannelConfiguration
        let rightHand: ServoChannelConfiguration
        let head: ServoChannelConfiguration
        let body: ServoChannelConfiguration
        let idleBehavior: IdleBehavior
        let loopInterval: TimeInterval
        let attachmentTimeout: TimeInterval
        var cameraRange: ClosedRange<Double> {
            (body.logicalRange.lowerBound + head.logicalRange.lowerBound)...(body.logicalRange.upperBound + head.logicalRange.upperBound)
        }
        
        static let `default` = FigurineConfiguration(
            leftHand: .init(
                name: "LeftHand",
                channel: 0,
                pulseRange: 550...2300,
                logicalRange: 0...1,
                homePosition: 0,
                velocityLimit: 60,
                orientation: .normal,
                voltage: nil
            ),
            rightHand: .init(
                name: "RightHand",
                channel: 1,
                pulseRange: 550...2300,
                logicalRange: 0...1,
                homePosition: 0,
                velocityLimit: 60,
                orientation: .reversed,
                voltage: nil
            ),
            head: .init(
                name: "Head",
                channel: 2,
                pulseRange: 700...1200,
                logicalRange: -30...30,
                homePosition: 0,
                velocityLimit: 90,
                orientation: .normal,
                voltage: nil
            ),
            body: .init(
                name: "Body",
                channel: 3,
                pulseRange: 800...1800,
                logicalRange: -90...90,
                homePosition: 0,
                velocityLimit: 90,
                orientation: .normal,
                voltage: nil
            ),
            idleBehavior: .sweep(range: -45...45, period: 8),
            loopInterval: 0.02,
            attachmentTimeout: 5
        )
    }
    
    struct ServoChannelConfiguration {
        enum Orientation {
            case normal
            case reversed
        }
        
        let name: String
        let channel: Int
        let pulseRange: ClosedRange<Double>
        let logicalRange: ClosedRange<Double>
        let homePosition: Double
        let velocityLimit: Double?
        let orientation: Orientation
        let voltage: RCServoVoltage?
    }
    
    enum FigurineError: Error {
        case alreadyRunning
        case attachmentTimeout(channel: Int)
    }
    
    private struct BehaviorState {
        var targetHeading: Double? = nil
        var idleBehavior: IdleBehavior
        var leftGesture: LeftHandGesture = .down
        var rightGesture: RightHandGesture = .down
    }
    
    private let configuration: FigurineConfiguration
    private let leftHandChannel: ServoChannel
    private let rightHandChannel: ServoChannel
    private let headChannel: ServoChannel
    private let bodyChannel: ServoChannel
    private let workerQueue = DispatchQueue(label: "RoboSanta.StateMachine", qos: .userInitiated)
    private let workerQueueKey = DispatchSpecificKey<Void>()
    
    private var pendingEvents: [Event] = []
    private var behavior: BehaviorState
    private var pose = FigurinePose(bodyAngle: 0, headAngle: 0, leftHand: 0, rightHand: 0)
    private var loopTask: Task<Void, Never>?
    private var lastUpdate = Date()
    private var leftWavePhase: Double = 0
    private var idlePhase: Double = 0
    private var leftIsWaving = false
    private var isRunning = false
    
    init(configuration: FigurineConfiguration = .default) {
        self.configuration = configuration
        self.behavior = BehaviorState(idleBehavior: configuration.idleBehavior)
        self.leftHandChannel = ServoChannel(configuration: configuration.leftHand)
        self.rightHandChannel = ServoChannel(configuration: configuration.rightHand)
        self.headChannel = ServoChannel(configuration: configuration.head)
        self.bodyChannel = ServoChannel(configuration: configuration.body)
        workerQueue.setSpecific(key: workerQueueKey, value: ())
    }
    
    deinit {
        let task: Task<Void, Never>? = syncOnWorkerQueue {
            let runningTask = loopTask
            loopTask = nil
            isRunning = false
            return runningTask
        }
        task?.cancel()
        syncOnWorkerQueue {
            pendingEvents.removeAll(keepingCapacity: true)
            teardownChannelsLocked()
        }
    }
    
    func start() async throws {
        var thrownError: Error?
        syncOnWorkerQueue {
            guard !isRunning else {
                thrownError = FigurineError.alreadyRunning
                return
            }
            do {
                try bodyChannel.open(timeout: configuration.attachmentTimeout)
                try headChannel.open(timeout: configuration.attachmentTimeout)
                try leftHandChannel.open(timeout: configuration.attachmentTimeout)
                try rightHandChannel.open(timeout: configuration.attachmentTimeout)
                isRunning = true
                lastUpdate = Date()
                updatePose(deltaTime: 0)
                applyPose()
                let task = Task { await self.runLoop() }
                loopTask = task
            } catch {
                thrownError = error
                teardownChannelsLocked()
            }
        }
        if let error = thrownError { throw error }
    }
    
    func stop() async {
        let task: Task<Void, Never>? = syncOnWorkerQueue {
            guard isRunning else { return nil }
            isRunning = false
            let runningTask = loopTask
            loopTask = nil
            return runningTask
        }
        task?.cancel()
        if let task {
            await task.value
        }
        syncOnWorkerQueue {
            pendingEvents.removeAll(keepingCapacity: true)
            leftIsWaving = false
            idlePhase = 0
            leftWavePhase = 0
            teardownChannelsLocked()
        }
    }
    
    func send(_ event: Event) {
        workerQueue.async { [weak self] in
            self?.pendingEvents.append(event)
        }
    }
    
    func currentPose() -> FigurinePose {
        syncOnWorkerQueue { pose }
    }
    
    func cameraHeading() -> Double {
        syncOnWorkerQueue { pose.cameraHeading }
    }
    
    private func runLoop() async {
        let nanos = UInt64(configuration.loopInterval * 1_000_000_000)
        while true {
            var keepRunning = false
            syncOnWorkerQueue {
                keepRunning = isRunning
                if keepRunning {
                    processEvents()
                    let now = Date()
                    let delta = now.timeIntervalSince(lastUpdate)
                    lastUpdate = now
                    updatePose(deltaTime: delta)
                    applyPose()
                }
            }
            if !keepRunning || Task.isCancelled { break }
            try? await Task.sleep(nanoseconds: nanos)
        }
    }
    
    private func processEvents() {
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)
        for event in events {
            switch event {
            case .idle:
                behavior.targetHeading = nil
                behavior.leftGesture = .down
                behavior.rightGesture = .down
                behavior.idleBehavior = configuration.idleBehavior
            case .aimCamera(let angle):
                behavior.targetHeading = clampCamera(angle)
            case .clearTarget:
                behavior.targetHeading = nil
            case .setLeftHand(let gesture):
                let wasWave = leftIsWaving
                behavior.leftGesture = gesture
                if case .wave = gesture {
                    if !wasWave { leftWavePhase = 0 }
                    leftIsWaving = true
                } else {
                    leftIsWaving = false
                }
            case .setRightHand(let gesture):
                behavior.rightGesture = gesture
            case .setIdleBehavior(let behavior):
                self.behavior.idleBehavior = behavior
                idlePhase = 0
            }
        }
    }
    
    private func updatePose(deltaTime: TimeInterval) {
        let resolved = resolveHeading(deltaTime: deltaTime)
        pose.bodyAngle = clampBody(resolved.body)
        pose.headAngle = clampHead(resolved.head)
        pose.leftHand = leftHandValue(deltaTime: deltaTime)
        pose.rightHand = rightHandValue()
    }
    
    private func resolveHeading(deltaTime: TimeInterval) -> (body: Double, head: Double) {
        let target = behavior.targetHeading ?? idleHeading(deltaTime: deltaTime)
        return splitHeading(target)
    }
    
    private func idleHeading(deltaTime: TimeInterval) -> Double {
        switch behavior.idleBehavior {
        case .none:
            return 0
        case .sweep(let range, let period):
            let span = max(period, 0.1)
            idlePhase = (idlePhase + deltaTime * (2 * .pi / span)).truncatingRemainder(dividingBy: 2 * .pi)
            let center = range.midPoint
            let amplitude = range.span / 2
            return center + sin(idlePhase) * amplitude
        }
    }
    
    private func splitHeading(_ heading: Double) -> (body: Double, head: Double) {
        let limitedHeading = clampCamera(heading)
        let bodyRange = configuration.body.logicalRange
        let headRange = configuration.head.logicalRange
        var body = bodyRange.clamp(limitedHeading)
        var head = limitedHeading - body
        if head > headRange.upperBound {
            let overflow = head - headRange.upperBound
            head = headRange.upperBound
            body = bodyRange.clamp(body + overflow)
        } else if head < headRange.lowerBound {
            let overflow = headRange.lowerBound - head
            head = headRange.lowerBound
            body = bodyRange.clamp(body - overflow)
        }
        return (body, head)
    }
    
    private func leftHandValue(deltaTime: TimeInterval) -> Double {
        switch behavior.leftGesture {
        case .down:
            return configuration.leftHand.logicalRange.lowerBound
        case .up:
            return configuration.leftHand.logicalRange.upperBound
        case .wave(let amplitude, let speed):
            let safeSpeed = max(speed, 0.2)
            leftWavePhase = (leftWavePhase + deltaTime * safeSpeed * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
            let span = min(amplitude, configuration.leftHand.logicalRange.span)
            let top = configuration.leftHand.logicalRange.upperBound
            let bottom = max(configuration.leftHand.logicalRange.lowerBound, top - span)
            let normalized = (sin(leftWavePhase) + 1) * 0.5
            return bottom + normalized * (top - bottom)
        }
    }
    
    private func rightHandValue() -> Double {
        let range = configuration.rightHand.logicalRange
        switch behavior.rightGesture {
        case .down:
            return range.lowerBound
        case .point:
            return range.lowerBound + range.span * 0.5
        case .emphasise:
            return range.upperBound
        }
    }
    
    private func applyPose() {
        bodyChannel.move(toLogical: pose.bodyAngle)
        headChannel.move(toLogical: pose.headAngle)
        leftHandChannel.move(toLogical: pose.leftHand)
        rightHandChannel.move(toLogical: pose.rightHand)
    }
    
    private func clampCamera(_ heading: Double) -> Double {
        configuration.cameraRange.clamp(heading)
    }
    
    private func clampBody(_ angle: Double) -> Double {
        configuration.body.logicalRange.clamp(angle)
    }
    
    private func clampHead(_ angle: Double) -> Double {
        configuration.head.logicalRange.clamp(angle)
    }
    
    private func syncOnWorkerQueue<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: workerQueueKey) != nil {
            return work()
        }
        return workerQueue.sync(execute: work)
    }

    private func teardownChannelsLocked() {
        leftHandChannel.shutdown()
        rightHandChannel.shutdown()
        headChannel.shutdown()
        bodyChannel.shutdown()
    }
}

private final class ServoChannel {
    private let configuration: StateMachine.ServoChannelConfiguration
    private let servo: RCServo = RCServo()
    private let handlers = Handlers()
    private var attached = false
    private var currentNormalized: Double?
    private var isOpen = false
    
    init(configuration: StateMachine.ServoChannelConfiguration) {
        self.configuration = configuration
        setupHandlers()
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
    
    func move(toLogical value: Double) {
        move(toLogical: value, force: false)
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
    }
    
    private func normalizedValue(for logical: Double) -> Double {
        let range = configuration.logicalRange
        let clamped = range.clamp(logical)
        let normalized = (clamped - range.lowerBound) / range.span
        switch configuration.orientation {
        case .normal:
            return normalized
        case .reversed:
            return 1 - normalized
        }
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
        _ = servo.error.addHandler(handlers.error_handler)
        _ = servo.attach.addHandler { [weak self] sender in
            self?.handlers.attach_handler(sender: sender)
            self?.attached = true
        }
        _ = servo.detach.addHandler { [weak self] sender in
            self?.handlers.detach_handler(sender: sender)
            self?.attached = false
        }
        _ = servo.velocityChange.addHandler(handlers.velocitychange_handler)
        _ = servo.positionChange.addHandler(handlers.positionchange_handler)
        _ = servo.targetPositionReached.addHandler(handlers.targetreached_handler)
    }

    private func configure(_ step: String, _ action: () throws -> Void) throws {
        do {
            try action()
        } catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            throw err
        } catch {
            print(error)
            throw error
        }
    }
    
    private func perform(_ step: String, _ action: () throws -> Void) {
        do {
            try action()
        } catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
        } catch {
            print(error)
        }
    }
    
    private func clamp(_ value: Double, min: Double?, max: Double?) -> Double {
        var lower = min
        var upper = max
        if let l = lower, let u = upper, l > u {
            lower = u
            upper = l
        }
        var clamped = value
        if let lower { clamped = Swift.max(clamped, lower) }
        if let upper { clamped = Swift.min(clamped, upper) }
        return clamped
    }
}

private extension ClosedRange where Bound == Double {
    var span: Double { upperBound - lowerBound }
    var midPoint: Double { (lowerBound + upperBound) / 2 }
    func clamp(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
