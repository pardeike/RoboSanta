// StateMachine.swift

import Foundation
import Dispatch

/// Drives the physical figurine by coordinating the four Phidget RC servos.
/// Feed it `Event`s from the outside world to influence Santa's pose.
final class StateMachine {
    enum Event: Equatable {
        case idle
        case aimCamera(Double) // degrees relative to Santa's forward direction
        case clearTarget
        case setLeftHand(LeftHandGesture)
        case setRightHand(RightHandGesture)
        case setIdleBehavior(IdleBehavior)
        case personDetected(relativeOffset: Double)
        case personLost
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
        case patrol(PatrolConfiguration)
        
        struct PatrolConfiguration: Equatable {
            let headings: [Double]
            let intervalRange: ClosedRange<TimeInterval>
            let transitionDurationRange: ClosedRange<TimeInterval>
            let headFollowRate: Double
            let bodyFollowRate: Double
            let headJitterRange: ClosedRange<Double>
        }
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
        let trackingBehavior: TrackingBehavior
        let headContributionRatio: Double
        let loopInterval: TimeInterval
        let attachmentTimeout: TimeInterval
        var cameraRange: ClosedRange<Double> {
            (body.logicalRange.lowerBound + head.logicalRange.lowerBound)...(body.logicalRange.upperBound + head.logicalRange.upperBound)
        }
        
        struct TrackingBehavior {
            let holdDuration: TimeInterval
            let headFollowRate: Double
            let bodyFollowRate: Double
            let cameraHorizontalFOV: Double
            let deadband: Double
            let predictionSmoothing: Double
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
            idleBehavior: .patrol(.init(
                headings: [-85, 85],
                intervalRange: 6...10,
                transitionDurationRange: 1.8...3.2,
                headFollowRate: 0.5,
                bodyFollowRate: 0.15,
                headJitterRange: (-5)...5
            )),
            trackingBehavior: .init(
                holdDuration: 6.0,
                headFollowRate: 0.7,
                bodyFollowRate: 0.25,
                cameraHorizontalFOV: 60,
                deadband: 0.08,
                predictionSmoothing: 0.3
            ),
            headContributionRatio: 0.4,
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
    
    private enum OrientationContext {
        case search
        case tracking
        case manual
    }
    
    private struct PatrolState {
        var headingIndex: Int = 0
        var currentHeading: Double = 0
        var startHeading: Double = 0
        var targetHeading: Double = 0
        var nextSwitch: Date = .distantPast
        var transitionStart: Date = .distantPast
        var transitionEnd: Date = .distantPast
    }

    private struct OffsetTracker {
        var lastOffset: Double?
        var lastUpdate: Date?
        var velCamDegPerSec: Double = 0
    }
    
    private struct BehaviorState {
        var idleBehavior: IdleBehavior
        var leftGesture: LeftHandGesture = .down
        var rightGesture: RightHandGesture = .down
        var manualHeading: Double?
        var manualOverride = false
        var trackingHeading: Double?
        var lastPersonDetection: Date?
        var currentHeading: Double = 0
        var lastScheduledHeading: Double = 0
        var bodyTarget: Double = 0
        var headTarget: Double = 0
        var desiredHeading: Double = 0
        var headJitterOffset: Double = 0
        var currentContext: OrientationContext = .search
        var patrolState = PatrolState()

        private(set) var focusStart: Date?
        var faceHeading: Double?
        var faceOffset: Double?

        var tracker = OffsetTracker()
        var lastFaceOffset: Double?

        mutating func focus(on heading: Double, now: Date) {
            trackingHeading = heading
            lastPersonDetection = now
            focusStart = focusStart ?? now
            faceHeading = heading
        }

        mutating func clearFocus() {
            trackingHeading = nil
            lastPersonDetection = nil
            focusStart = nil
            faceHeading = nil
            faceOffset = nil
            tracker = OffsetTracker()
            lastFaceOffset = nil
        }

        func personFocused(for now: Date, longerThan duration: TimeInterval) -> Bool {
            guard let start = focusStart else { return false }
            return now.timeIntervalSince(start) >= duration
        }
    }
    
    private let configuration: FigurineConfiguration
    private let telemetry: TelemetryLogger
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

    // Predictor / motion limits
    private let leadSeconds: TimeInterval = 0.15
    private let velCapDegPerSec: Double = 120
    private let headRateCapDegPerSec: Double = 150
    private let bodyRateCapDegPerSec: Double = 90

    init(configuration: FigurineConfiguration = .default, telemetry: TelemetryLogger = .shared) {
        self.configuration = configuration
        self.telemetry = telemetry
        self.behavior = BehaviorState(idleBehavior: configuration.idleBehavior)
        self.leftHandChannel = ServoChannel(configuration: configuration.leftHand)
        self.rightHandChannel = ServoChannel(configuration: configuration.rightHand)
        self.headChannel = ServoChannel(configuration: configuration.head)
        self.bodyChannel = ServoChannel(configuration: configuration.body)
        let telemetry: (String, [String: CustomStringConvertible]) -> Void = { [weak self] event, values in
            self?.logEvent(event, values: values)
        }
        leftHandChannel.setTelemetryLogger(telemetry)
        rightHandChannel.setTelemetryLogger(telemetry)
        headChannel.setTelemetryLogger(telemetry)
        bodyChannel.setTelemetryLogger(telemetry)
        workerQueue.setSpecific(key: workerQueueKey, value: ())
        configureInitialPatrolState(now: Date())
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
                updatePose(now: lastUpdate, deltaTime: 0)
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
            guard let self else { return }
            self.pendingEvents.append(event)
            print("[event] \(event)")
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
                    let now = Date()
                    processEvents(now: now)
                    let delta = now.timeIntervalSince(lastUpdate)
                    lastUpdate = now
                    updatePose(now: now, deltaTime: delta)
                    applyPose()
                }
            }
            if !keepRunning || Task.isCancelled { break }
            try? await Task.sleep(nanoseconds: nanos)
        }
    }
    
    private func processEvents(now: Date) {
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)

        // Coalesce personDetected to newest offset within this tick
        var lastDetectedOffset: Double?

        for event in events {
            switch event {
            case .idle:
                behavior.manualOverride = false
                behavior.manualHeading = nil
                behavior.clearFocus()
                behavior.leftGesture = .down
                behavior.rightGesture = .down
                behavior.idleBehavior = configuration.idleBehavior
                configureInitialPatrolState(now: now)
                logState("mode.idle")

            case .aimCamera(let angle):
                behavior.manualOverride = true
                behavior.manualHeading = clampCamera(angle)
                logState("mode.manual", values: ["target": angle])

            case .clearTarget:
                behavior.manualOverride = false
                behavior.manualHeading = nil

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

            case .setIdleBehavior(let newBehavior):
                behavior.idleBehavior = newBehavior
                idlePhase = 0
                configureInitialPatrolState(now: now)

            case .personDetected(let offset):
                lastDetectedOffset = offset

            case .personLost:
                behavior.clearFocus()
                logEvent("tracking.lost", values: [:] as [String: CustomStringConvertible])
                logState("tracking.lost")
            }
        }

        if let o = lastDetectedOffset {
            updateTrackingHeading(offset: o, now: now, currentHeading: pose.cameraHeading)
        }
    }
    
    private func updatePose(now: Date, deltaTime: TimeInterval) {
        let (desiredHeading, context) = desiredHeading(now: now, deltaTime: deltaTime)
        if orientationNeedsUpdate(for: desiredHeading, context: context) {
            scheduleOrientationChange(to: desiredHeading, context: context, now: now)
        }
        updateHeadAndBodyTargets(deltaTime: deltaTime)
        pose.bodyAngle = behavior.bodyTarget
        pose.headAngle = behavior.headTarget
        pose.leftHand = leftHandValue(deltaTime: deltaTime)
        pose.rightHand = rightHandValue()
    }
    
    private func idleHeading(now: Date, deltaTime: TimeInterval) -> Double {
        switch behavior.idleBehavior {
        case .none:
            return 0
        case .sweep(let range, let period):
            let span = max(period, 0.1)
            idlePhase = (idlePhase + deltaTime * (2 * .pi / span)).truncatingRemainder(dividingBy: 2 * .pi)
            let center = range.midPoint
            let amplitude = range.span / 2
            return center + sin(idlePhase) * amplitude
        case .patrol(let config):
            guard !config.headings.isEmpty else { return 0 }
            var state = behavior.patrolState
            if now >= state.nextSwitch {
                state.headingIndex = (state.headingIndex + 1) % config.headings.count
                state.startHeading = state.currentHeading
                state.targetHeading = config.headings[state.headingIndex]
                state.transitionStart = now
                state.transitionEnd = now + randomInterval(in: config.transitionDurationRange)
                state.nextSwitch = state.transitionEnd + randomInterval(in: config.intervalRange)
                logEvent("patrol.transition", values: [
                    "target": state.targetHeading,
                    "duration": state.transitionEnd.timeIntervalSince(state.transitionStart),
                    "nextSwitch": state.nextSwitch.timeIntervalSince1970
                ])
                logState("patrol.target", values: ["heading": state.targetHeading])
            }
            if state.transitionEnd > state.transitionStart, now < state.transitionEnd {
                let duration = state.transitionEnd.timeIntervalSince(state.transitionStart)
                let progress = duration > 0 ? (now.timeIntervalSince(state.transitionStart) / duration) : 1
                state.currentHeading = lerp(state.startHeading, state.targetHeading, t: progress.clamped(to: 0...1))
            } else {
                state.currentHeading = state.targetHeading
            }
            behavior.patrolState = state
            return state.currentHeading
        }
    }
    
    private func desiredHeading(now: Date, deltaTime: TimeInterval) -> (Double, OrientationContext) {
        if behavior.manualOverride, let manual = behavior.manualHeading {
            return (clampCamera(manual), .manual)
        }
        if let lastSeen = behavior.lastPersonDetection,
           now.timeIntervalSince(lastSeen) <= configuration.trackingBehavior.holdDuration,
           let tracked = behavior.trackingHeading ?? behavior.faceHeading {
            return (tracked, .tracking)
        } else {
            if let last = behavior.lastPersonDetection,
               now.timeIntervalSince(last) > configuration.trackingBehavior.holdDuration {
                behavior.clearFocus()
            }
        }
        return (idleHeading(now: now, deltaTime: deltaTime), .search)
    }
    
    private func orientationNeedsUpdate(for heading: Double, context: OrientationContext) -> Bool {
        let threshold = 0.5
        if abs(heading - behavior.lastScheduledHeading) > threshold { return true }
        if behavior.currentContext != context { return true }
        return false
    }
    
    private func scheduleOrientationChange(to heading: Double, context: OrientationContext, now: Date) {
        let limitedHeading = clampCamera(heading)
        behavior.desiredHeading = limitedHeading
        let previousContext = behavior.currentContext
        behavior.currentContext = context
        behavior.lastScheduledHeading = limitedHeading
        let params = orientationParameters(for: context)
        behavior.headJitterOffset = randomValue(in: params.headJitter) * 0.1
        logEvent("orientation.schedule", values: [
            "context": contextName(context),
            "heading": limitedHeading
        ])
        if previousContext != context {
            switch context {
            case .tracking:
                logState("mode.tracking")
            case .search:
                logState("mode.search")
            case .manual:
                logState("mode.manual")
            }
        }
    }
    
    private func updateHeadAndBodyTargets(deltaTime: TimeInterval) {
        let desired = behavior.desiredHeading
        let context = behavior.currentContext
        let params = orientationParameters(for: context)

        // Gain scheduling: slower near center while tracking
        let offsetMag = abs(behavior.lastFaceOffset ?? 1.0)
        let gain = (context == .tracking) ? (0.35 + 0.65 * min(1.0, offsetMag)) : 1.0

        let jitter = context == .search ? behavior.headJitterOffset : 0

        // Head
        let rawHeadDemand = clampHead(desired - behavior.bodyTarget + jitter)
        let headRate = (params.headFollowRate.clamped(to: 0.1...1.0)) * gain
        var newHead = behavior.headTarget + (rawHeadDemand - behavior.headTarget) * headRate
        if deltaTime > 0 {
            newHead = approach(current: behavior.headTarget,
                               target: newHead,
                               maxDelta: headRateCapDegPerSec * deltaTime)
        }
        newHead = clampHead(newHead)

        // Body follows head
        let bodyDemand = clampBody(desired - newHead)
        let bodyRate = (params.bodyFollowRate.clamped(to: 0...1.0)) * gain
        var newBody = behavior.bodyTarget + (bodyDemand - behavior.bodyTarget) * bodyRate
        if deltaTime > 0 {
            newBody = approach(current: behavior.bodyTarget,
                               target: newBody,
                               maxDelta: bodyRateCapDegPerSec * deltaTime)
        }
        newBody = clampBody(newBody)

        behavior.headTarget = newHead
        behavior.bodyTarget = newBody
    }
    
    private func orientationParameters(for context: OrientationContext) -> (headFollowRate: Double, bodyFollowRate: Double, headJitter: ClosedRange<Double>) {
        switch context {
        case .search:
            if case .patrol(let config) = behavior.idleBehavior {
                return (config.headFollowRate, config.bodyFollowRate, config.headJitterRange)
            }
            return (0.5, 0.15, 0...0)
        case .tracking, .manual:
            let tracking = configuration.trackingBehavior
            return (tracking.headFollowRate, tracking.bodyFollowRate, 0...0)
        }
    }
    
    // Camera‑space predictor (offset derivative), then convert to absolute
    private func updateTrackingHeading(offset: Double, now: Date, currentHeading: Double) {
        let cfg = configuration.trackingBehavior
        let halfFOV = max(1.0, cfg.cameraHorizontalFOV / 2.0)

        behavior.lastFaceOffset = offset

        // If already tracking and offset inside deadband, sustain focus
        if abs(offset) < cfg.deadband, behavior.faceHeading != nil {
            behavior.focus(on: behavior.faceHeading!, now: now)
            return
        }

        let measAbs = clampCamera(currentHeading + offset * halfFOV)

        var tr = behavior.tracker
        let dtRaw = tr.lastUpdate.map { now.timeIntervalSince($0) } ?? 0
        let dt = max(1.0/60.0, min(0.12, dtRaw == 0 ? configuration.loopInterval : dtRaw))

        if let lastOff = tr.lastOffset {
            let rawVel = ((offset - lastOff) * halfFOV) / dt
            let alpha = max(0.05, min(0.95, 1 - cfg.predictionSmoothing))
            let vSmoothed = tr.velCamDegPerSec + (rawVel - tr.velCamDegPerSec) * alpha
            tr.velCamDegPerSec = max(-velCapDegPerSec, min(velCapDegPerSec, vSmoothed))
        } else {
            tr.velCamDegPerSec = 0
        }
        tr.lastOffset = offset
        tr.lastUpdate = now
        behavior.tracker = tr

        let leadAllowed = abs(offset) > 0.15 ? leadSeconds : 0.0
        let leadDegCap = 8.0
        let leadTerm = max(-leadDegCap, min(leadDegCap, tr.velCamDegPerSec * leadAllowed))

        let predictedAbs = clampCamera(currentHeading + offset * halfFOV + leadTerm)

        behavior.faceOffset = offset
        behavior.faceHeading = measAbs
        behavior.trackingHeading = predictedAbs
        behavior.focus(on: predictedAbs, now: now)

        logEvent("tracking.update", values: [
            "offset": offset,
            "meas": measAbs,
            "pred": predictedAbs
        ])
        logState("tracking.face", values: ["meas": measAbs, "pred": predictedAbs, "off": offset])
    }
    
    private func configureInitialPatrolState(now: Date) {
        if case .patrol(let config) = behavior.idleBehavior, !config.headings.isEmpty {
            let index = Int.random(in: 0..<config.headings.count)
            behavior.patrolState.headingIndex = index
            let heading = config.headings[index]
            behavior.patrolState.currentHeading = heading
            behavior.patrolState.startHeading = heading
            behavior.patrolState.targetHeading = heading
            behavior.patrolState.transitionStart = now
            behavior.patrolState.transitionEnd = now
            behavior.patrolState.nextSwitch = now + randomInterval(in: config.intervalRange)
            behavior.bodyTarget = heading
            behavior.headTarget = heading
            behavior.desiredHeading = heading
            logEvent("patrol.init", values: [
                "heading": heading,
                "nextSwitch": behavior.patrolState.nextSwitch.timeIntervalSince1970
            ])
            logState("patrol.target", values: ["heading": heading])
        } else {
            behavior.patrolState.headingIndex = 0
            behavior.patrolState.currentHeading = 0
            behavior.patrolState.startHeading = 0
            behavior.patrolState.targetHeading = 0
            behavior.patrolState.transitionStart = now
            behavior.patrolState.transitionEnd = now
            behavior.patrolState.nextSwitch = now
            behavior.bodyTarget = 0
            behavior.headTarget = 0
            behavior.desiredHeading = 0
        }
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

    private func approach(current: Double, target: Double, maxDelta: Double) -> Double {
        if target > current { return min(target, current + maxDelta) }
        else { return max(target, current - maxDelta) }
    }

    private func syncOnWorkerQueue<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: workerQueueKey) != nil {
            return work()
        }
        return workerQueue.sync(execute: work)
    }
    
    private func telemetryPayload(from values: [String: CustomStringConvertible]) -> [String: Any]? {
        var payload: [String: Any] = ["ts": Date().timeIntervalSince1970]
        for (key, value) in values {
            if let double = value as? Double {
                payload[key] = double
            } else if let int = value as? Int {
                payload[key] = int
            } else if let bool = value as? Bool {
                payload[key] = bool
            } else {
                payload[key] = value.description
            }
        }
        return payload
    }
    
    private func logEvent(_ type: String, values: [String: CustomStringConvertible] = [:]) {
        var payload: [String: CustomStringConvertible] = ["type": type]
        for (key, value) in values {
            payload[key] = value
        }
        if let common = telemetryPayload(from: payload), let json = telemetry.serialize(common) {
            telemetry.write(line: json)
        }
    }

    private func logState(_ label: String, values: [String: CustomStringConvertible] = [:]) {
        var message = "[state] \(label)"
        if !values.isEmpty {
            let details = values.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            message += " " + details
        }
        print(message)
    }
    
    private func contextName(_ context: OrientationContext) -> String {
        switch context {
        case .manual: return "manual"
        case .tracking: return "tracking"
        case .search: return "search"
        }
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
    private var attached = false
    private var currentNormalized: Double?
    private var isOpen = false
    private var telemetryLogger: ((String, [String: CustomStringConvertible]) -> Void)?
    
    init(configuration: StateMachine.ServoChannelConfiguration) {
        self.configuration = configuration
        setupHandlers()
    }
    
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void) {
        telemetryLogger = logger
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
        logTelemetry("servo.command", values: ["target": normalized])
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
        _ = servo.error.addHandler { [weak self] sender, data in
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
            self?.logTelemetry("servo.position", values: ["value": position])
        }
        _ = servo.targetPositionReached.addHandler { [weak self] _, position in
            self?.logTelemetry("servo.targetReached", values: ["value": position])
        }
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
            logTelemetry("servo.error", values: ["step": step, "code": err.errorCode.rawValue, "description": err.description])
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
    
    private func logTelemetry(_ event: String, values: [String: CustomStringConvertible] = [:]) {
        var merged = values
        merged["servo"] = configuration.name
        telemetryLogger?(event, merged)
    }
}

private func randomValue(in range: ClosedRange<Double>) -> Double {
    let lower = Swift.min(range.lowerBound, range.upperBound)
    let upper = Swift.max(range.lowerBound, range.upperBound)
    if lower == upper { return lower }
    return Double.random(in: lower...upper)
}

private func randomInterval(in range: ClosedRange<TimeInterval>) -> TimeInterval {
    let lower = Swift.min(range.lowerBound, range.upperBound)
    let upper = Swift.max(range.lowerBound, range.upperBound)
    if lower == upper { return lower }
    return Double.random(in: lower...upper)
}

private func lerp(_ start: Double, _ end: Double, t: Double) -> Double {
    start + (end - start) * t
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension ClosedRange where Bound == Double {
    var span: Double { upperBound - lowerBound }
    var midPoint: Double { (lowerBound + upperBound) / 2 }
    func clamp(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
