// StateMachine.swift

import Foundation
import Dispatch

/// Drives the physical figurine by coordinating the four Phidget RC servos.
/// Feed it `Event`s from the outside world to influence Santa's pose.
/// All settings can be found in StateMachineSettings.swift and are documented there
final class StateMachine {
    
    enum Event: Equatable {
        case idle
        case aimCamera(Double) // degrees relative to Santa's forward direction
        case clearTarget
        case setLeftHand(LeftHandGesture)
        case setRightHand(RightHandGesture)
        case setIdleBehavior(IdleBehavior)
        case personDetected(relativeOffset: Double) // -1...+1, 0 is center
        case personLost
    }
    
    enum LeftHandGesture: Equatable {
        case down
        case up
        case wave(amplitude: Double = 0.12, speed: Double = 1.8)
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
            let includeCameraBounds: Bool
        }
    }
    
    struct FigurinePose {
        var bodyAngle: Double = 0
        var headAngle: Double = 0
        var leftHand: Double = 0
        var rightHand: Double = 0
        var cameraHeading: Double { bodyAngle + headAngle }
    }
    
    struct FigurineConfiguration {
        let leftHand: ServoChannelConfiguration
        let rightHand: ServoChannelConfiguration
        let head: ServoChannelConfiguration
        let body: ServoChannelConfiguration
        let idleBehavior: IdleBehavior
        let trackingBehavior: TrackingBehavior
        let leftHandCooldownDuration: TimeInterval
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
            let deadband: Double         // normalized offset deadband (0..1)
            let predictionSmoothing: Double // 0..1 (closer to 1 = more smoothing)
        }
        
        static let `default` = StateMachine.Settings.default.figurineConfiguration
    }
    
    struct ServoChannelConfiguration {
        enum Orientation { case normal, reversed }
        let name: String
        let channel: Int
        let pulseRange: ClosedRange<Double>
        let logicalRange: ClosedRange<Double>
        let homePosition: Double
        let velocityLimit: Double?
        let orientation: Orientation
        let voltage: RCServoVoltage?
        let stallGuard: StallGuard?

        struct StallGuard {
            let tolerance: Double          // acceptable error band (logical units)
            let holdDuration: TimeInterval // time to wait while steady before freezing the target
            let minMovement: Double        // ignore movement smaller than this when deciding if we're still moving
            let backoff: Double            // amount to pull back from a range edge when settling
        }
    }
    
    enum FigurineError: Error {
        case alreadyRunning
        case attachmentTimeout(channel: Int)
    }
    
    private enum OrientationContext { case search, tracking, manual }
    private enum LeftHandAutoState: Equatable { 
        case lowered
        case raising
        case waving(cyclesRemaining: Int, phase: WavePhase)
        case pausingAtTop
        case lowering
        
        enum WavePhase {
            case movingDown
            case movingUp
        }
    }
    private enum ServoAxis { case head, body }
    
    private struct PatrolState {
        var lowerHeading: Double = 0
        var upperHeading: Double = 0
        var nextTargetIsUpper: Bool = true
        var currentHeading: Double = 0
        var startHeading: Double = 0
        var targetHeading: Double = 0
        var nextSwitch: Date = .distantPast
        var transitionStart: Date = .distantPast
        var transitionEnd: Date = .distantPast
        var hasExtremes = false
    }

    private struct OffsetTracker {
        var lastOffset: Double?          // last raw offset (-1..+1)
        var lastFiltered: Double?        // last filtered offset (-1..+1)
        var lastUpdate: Date?
        var velCamDegPerSec: Double = 0  // camera-space (deg/s)
    }

    private struct ServoStallState {
        var lastTarget: Double?
        var frozenTarget: Double?
        var lastMeasurement: Double?
        var lastMeasurementAt: Date?
        var lastMovementAt: Date?
        var lastCommandAt: Date?
        var frozenEdge: Edge?

        enum Edge { case lower, upper }
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
        var faceOffset: Double?          // last raw offset (-1..+1)
        var lastFaceOffset: Double?
        var facesVisible = false

        var tracker = OffsetTracker()
        var centerHoldBegan: Date?

        var leftHandAutoState: LeftHandAutoState = .lowered
        var leftHandTargetAngle: Double?
        var leftHandRaisedTimestamp: Date?
        var leftHandPauseEndTime: Date?
        var leftHandCooldownActive = false
        var leftHandCooldownUntil: Date?
        var leftHandAutopilotArmed = false
        var leftHandMeasuredAngle: Double?
        var leftHandLastLoggedAngle: Double?
        var rightHandMeasuredAngle: Double?

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
            lastFaceOffset = nil
            tracker = OffsetTracker()
            centerHoldBegan = nil
        }

        func personFocused(for now: Date, longerThan duration: TimeInterval) -> Bool {
            guard let start = focusStart else { return false }
            return now.timeIntervalSince(start) >= duration
        }
    }
    
    private let configuration: FigurineConfiguration
    private let telemetry: TelemetryLogger
    private let leftHandDriver: ServoDriver
    private let rightHandDriver: ServoDriver
    private let headDriver: ServoDriver
    private let bodyDriver: ServoDriver
    private let settings: Settings
    private let loggingEnabled: Bool
    private let workerQueue = DispatchQueue(label: "RoboSanta.StateMachine", qos: .userInitiated)
    private let workerQueueKey = DispatchSpecificKey<Void>()
    
    private var pendingEvents: [Event] = []
    private var behavior: BehaviorState
    private var pose = FigurinePose()
    private var measuredBodyAngle: Double?
    private var measuredHeadAngle: Double?
    private var bodyStall = ServoStallState()
    private var headStall = ServoStallState()
    private var loopTask: Task<Void, Never>?
    private var lastUpdate = Date()
    private var idlePhase: Double = 0
    private var isRunning = false
    
    init(configuration: FigurineConfiguration = .default, telemetry: TelemetryLogger = .shared, settings: Settings = .default, driverFactory: ServoDriverFactory = PhidgetServoDriverFactory()) {
        let mergedSettings = settings.withFigurineConfiguration(configuration)
        self.settings = mergedSettings
        self.configuration = mergedSettings.figurineConfiguration
        self.telemetry = telemetry
        self.loggingEnabled = mergedSettings.loggingEnabled
        self.behavior = BehaviorState(idleBehavior: self.configuration.idleBehavior)
        self.leftHandDriver = driverFactory.createDriver(for: self.configuration.leftHand)
        self.rightHandDriver = driverFactory.createDriver(for: self.configuration.rightHand)
        self.headDriver = driverFactory.createDriver(for: self.configuration.head)
        self.bodyDriver = driverFactory.createDriver(for: self.configuration.body)
        let telemetryLogger: (String, [String: CustomStringConvertible]) -> Void = { [weak self] event, values in
            self?.logEvent(event, values: values)
        }
        leftHandDriver.setTelemetryLogger(telemetryLogger)
        rightHandDriver.setTelemetryLogger(telemetryLogger)
        headDriver.setTelemetryLogger(telemetryLogger)
        bodyDriver.setTelemetryLogger(telemetryLogger)
        leftHandDriver.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async {
                self.behavior.leftHandMeasuredAngle = angle
                self.handleLeftHandPositionUpdate(angle: angle, now: Date())
            }
        }
        rightHandDriver.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async {
                self.behavior.rightHandMeasuredAngle = angle
            }
        }
        bodyDriver.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async {
                let now = Date()
                self.measuredBodyAngle = angle
                self.updateStallMeasurement(for: .body, value: angle, now: now)
            }
        }
        headDriver.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async {
                let now = Date()
                self.measuredHeadAngle = angle
                self.updateStallMeasurement(for: .head, value: angle, now: now)
            }
        }
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
            teardownDriversLocked()
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
                try bodyDriver.open(timeout: configuration.attachmentTimeout)
                try headDriver.open(timeout: configuration.attachmentTimeout)
                try leftHandDriver.open(timeout: configuration.attachmentTimeout)
                try rightHandDriver.open(timeout: configuration.attachmentTimeout)
                isRunning = true
                bodyStall = ServoStallState()
                headStall = ServoStallState()
                lastUpdate = Date()
                updatePose(now: lastUpdate, deltaTime: 0)
                applyPose()
                let task = Task { await self.runLoop() }
                loopTask = task
            } catch {
                thrownError = error
                teardownDriversLocked()
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
        if let task { await task.value }
        syncOnWorkerQueue {
            pendingEvents.removeAll(keepingCapacity: true)
            resetLeftHandAutopilot(clearTimeCooldown: true)
            idlePhase = 0
            bodyStall = ServoStallState()
            headStall = ServoStallState()
            teardownDriversLocked()
        }
    }
    
    func send(_ event: Event) {
        workerQueue.async { [weak self] in
            guard let self else { return }
            self.pendingEvents.append(event)
            if loggingEnabled {
                switch event {
                case .personDetected, .personLost:
                    // Only log detection transitions inside processEvents to avoid spam.
                    break
                default:
                    logState("event", values: ["value": "\(event)"])
                }
            }
        }
    }
    
    func currentPose() -> FigurinePose { syncOnWorkerQueue { pose } }
    func cameraHeading() -> Double { syncOnWorkerQueue { cameraHeadingEstimateLocked() } }
    
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
    
    private func cameraHeadingEstimateLocked() -> Double {
        if let body = measuredBodyAngle, let head = measuredHeadAngle {
            return clampCamera(body + head)
        }
        return pose.cameraHeading
    }
    
    private func processEvents(now: Date) {
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)

        // Use the latest personDetected per tick to avoid chasing intra-frame jitter.
        var lastDetectedOffset: Double?
        let previouslyVisible = behavior.facesVisible
        var sawPerson = false

        for event in events {
            switch event {
            case .idle:
                behavior.manualOverride = false
                behavior.manualHeading = nil
                behavior.clearFocus()
                resetLeftHandAutopilot()
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
                setLeftGesture(gesture)

            case .setRightHand(let gesture):
                behavior.rightGesture = gesture

            case .setIdleBehavior(let newBehavior):
                behavior.idleBehavior = newBehavior
                idlePhase = 0
                configureInitialPatrolState(now: now)

            case .personDetected(let offset):
                lastDetectedOffset = offset
                sawPerson = true

            case .personLost:
                let hadFocus = behavior.focusStart != nil
                let handWasActive = behavior.leftHandAutoState != .lowered
                behavior.clearFocus()
                // Only start cooldown if hand was actively raised/waving
                if hadFocus && handWasActive { startLeftHandCooldown(now: now) }
                // Only reset autopilot if not in the middle of lowering.
                // If lowering, the position observer will complete the sequence.
                if behavior.leftHandAutoState != .lowering {
                    resetLeftHandAutopilot()
                }
                behavior.facesVisible = false
                logEvent("tracking.lost")
                logState("tracking.lost")
            }
        }

        if sawPerson {
            behavior.facesVisible = true
        } else if lastDetectedOffset == nil {
            behavior.facesVisible = false
        }

        let detectionGained = !previouslyVisible && behavior.facesVisible
        let detectionLost = previouslyVisible && !behavior.facesVisible
        if detectionGained {
            logState("event.personDetected")
        } else if detectionLost {
            logState("event.personLost")
        }

        if !previouslyVisible && behavior.facesVisible {
            armLeftHandAutopilotIfEligible(now: now)
        }

        if let o = lastDetectedOffset {
            let heading = cameraHeadingEstimateLocked()
            updateTrackingHeading(offset: o, now: now, currentHeading: heading)
        }
    }
    
    private func updatePose(now: Date, deltaTime: TimeInterval) {
        let (desiredHeading, context) = desiredHeading(now: now, deltaTime: deltaTime)
        if orientationNeedsUpdate(for: desiredHeading, context: context) {
            scheduleOrientationChange(to: desiredHeading, context: context, now: now)
        }
        updateHeadAndBodyTargets(now: now, deltaTime: deltaTime)

        pose.bodyAngle = behavior.bodyTarget
        pose.headAngle = behavior.headTarget
        updateLeftHandAutopilot(now: now)
        pose.leftHand = leftHandValue(deltaTime: deltaTime)
        pose.rightHand = rightHandValue()

        logEvent("loop.pose", values: [
            "ctx": contextName(behavior.currentContext),
            "cam.des": behavior.desiredHeading,
            "body.tgt": behavior.bodyTarget,
            "head.tgt": behavior.headTarget
        ])
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
            var state = behavior.patrolState
            if !state.hasExtremes {
                guard let initial = initialPatrolState(for: config, now: now) else {
                    behavior.patrolState = PatrolState()
                    return 0
                }
                state = initial
            }
            if now >= state.nextSwitch {
                let nextTarget = state.nextTargetIsUpper ? state.upperHeading : state.lowerHeading
                state.startHeading = state.currentHeading
                state.targetHeading = nextTarget
                state.transitionStart = now
                state.transitionEnd = now + randomInterval(in: config.transitionDurationRange)
                state.nextSwitch = state.transitionEnd + randomInterval(in: config.intervalRange)
                state.nextTargetIsUpper.toggle()
                logEvent("patrol.transition", values: [
                    "target": state.targetHeading,
                    "duration": state.transitionEnd.timeIntervalSince(state.transitionStart),
                    "next": state.nextSwitch.timeIntervalSince1970
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

    private func initialPatrolState(for config: IdleBehavior.PatrolConfiguration, now: Date) -> PatrolState? {
        guard let extremes = resolvedPatrolExtremes(for: config) else { return nil }
        var state = PatrolState()
        state.hasExtremes = true
        state.lowerHeading = extremes.lower
        state.upperHeading = extremes.upper
        let startAtUpper = Bool.random()
        state.nextTargetIsUpper = !startAtUpper
        let start = startAtUpper ? state.upperHeading : state.lowerHeading
        state.currentHeading = start
        state.startHeading = start
        state.targetHeading = start
        state.transitionStart = now
        state.transitionEnd = now
        state.nextSwitch = now + randomInterval(in: config.intervalRange)
        return state
    }

    private func resolvedPatrolExtremes(for config: IdleBehavior.PatrolConfiguration) -> (lower: Double, upper: Double)? {
        var values = config.headings.map { clampCamera($0) }
        if config.includeCameraBounds {
            let bounds = configuration.cameraRange
            values.append(bounds.lowerBound)
            values.append(bounds.upperBound)
        }
        values.sort()
        var deduped: [Double] = []
        let epsilon = settings.patrolHeadingDedupEpsilon
        for value in values {
            if let last = deduped.last, abs(last - value) < epsilon { continue }
            deduped.append(value)
        }
        guard let lower = deduped.first, let upper = deduped.last else { return nil }
        return (lower, upper)
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
                if behavior.focusStart != nil { startLeftHandCooldown(now: now) }
                behavior.clearFocus()
                behavior.facesVisible = false
                resetLeftHandAutopilot()
            }
        }
        return (idleHeading(now: now, deltaTime: deltaTime), .search)
    }
    
    private func orientationNeedsUpdate(for heading: Double, context: OrientationContext) -> Bool {
        let threshold = settings.orientationRescheduleThreshold
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
            // Clear frozen stall states when context changes to allow smooth transitions
            clearFrozenStallStates(now: now)
            // When returning to search mode, sync patrol to start from current position
            if context == .search && previousContext == .tracking {
                syncPatrolFromCurrentHeading(now: now)
            }
            switch context {
            case .tracking: logState("mode.tracking")
            case .search:   logState("mode.search")
            case .manual:   logState("mode.manual")
            }
        }
    }
    
    /// Clears the frozen target states for head and body servos.
    /// Called when the orientation context changes to allow free movement.
    /// Also resets timing state to prevent immediate re-freeze.
    private func clearFrozenStallStates(now: Date) {
        // Clear frozen targets and edges
        headStall.frozenTarget = nil
        headStall.frozenEdge = nil
        bodyStall.frozenTarget = nil
        bodyStall.frozenEdge = nil
        // Reset movement timestamps to prevent immediate re-freeze
        // Keep lastMeasurement/lastMeasurementAt as they reflect actual servo position
        headStall.lastMovementAt = now
        headStall.lastCommandAt = now
        bodyStall.lastMovementAt = now
        bodyStall.lastCommandAt = now
        logEvent("stall.cleared", values: ["reason": "context_change"])
    }
    
    /// Syncs patrol state to continue from the current camera heading.
    /// Called when transitioning from tracking to search to avoid jumps.
    private func syncPatrolFromCurrentHeading(now: Date) {
        guard case .patrol(let config) = behavior.idleBehavior else { return }
        
        // Get current camera heading as the starting point
        let currentHeading = cameraHeadingEstimateLocked()
        
        // Ensure patrol extremes are set
        if !behavior.patrolState.hasExtremes {
            guard let extremes = resolvedPatrolExtremes(for: config) else { return }
            behavior.patrolState.hasExtremes = true
            behavior.patrolState.lowerHeading = extremes.lower
            behavior.patrolState.upperHeading = extremes.upper
        }
        
        // Update patrol state to start from current position
        behavior.patrolState.currentHeading = currentHeading
        behavior.patrolState.startHeading = currentHeading
        behavior.patrolState.targetHeading = currentHeading
        behavior.patrolState.transitionStart = now
        behavior.patrolState.transitionEnd = now
        
        // Use configured pause duration when resuming from tracking
        behavior.patrolState.nextSwitch = now + settings.patrolResumePauseDuration
        
        // Decide next direction based on current position relative to patrol center
        let center = (behavior.patrolState.lowerHeading + behavior.patrolState.upperHeading) / 2
        behavior.patrolState.nextTargetIsUpper = currentHeading < center
        
        logEvent("patrol.sync", values: [
            "from": currentHeading,
            "nextSwitch": behavior.patrolState.nextSwitch.timeIntervalSince1970
        ])
        logState("patrol.resumed", values: ["heading": currentHeading])
    }
    
    private func updateHeadAndBodyTargets(now: Date, deltaTime: TimeInterval) {
        let desired = behavior.desiredHeading
        let context = behavior.currentContext
        let params = orientationParameters(for: context)

        // Head demand relative to the (slow) body reference.
        let headShare = (context == .search ? configuration.headContributionRatio.clamped(to: 0...1) : 1.0)
        let headJitter = (context == .search ? behavior.headJitterOffset : 0)
        let deltaHeading = (desired - behavior.bodyTarget) * headShare
        let rawHeadDemand = clampHead(deltaHeading + headJitter)

        // Gain scheduling: smaller gains near center during tracking
        let offMag = abs(behavior.lastFaceOffset ?? 1.0)
        let nearCenterGain = (context == .tracking) ? (0.35 + 0.65 * min(1.0, offMag)) : 1.0

        // Head update with rate cap
        let headRate = (params.headFollowRate.clamped(to: 0.1...1.0)) * nearCenterGain
        var newHead = behavior.headTarget + (rawHeadDemand - behavior.headTarget) * headRate
        if deltaTime > 0 {
            newHead = approach(current: behavior.headTarget,
                               target: newHead,
                               maxDelta: settings.headRateCapDegPerSec * deltaTime)
        }
        newHead = clampHead(newHead)

        // Body follows head, but freeze near center to kill oscillation
        var bodyRate = (params.bodyFollowRate.clamped(to: 0...1.0)) * nearCenterGain
        if context == .tracking, let off = behavior.lastFaceOffset, abs(off) < settings.centerHoldOffsetNorm {
            bodyRate = 0 // head does the fine work
        }
        let bodyDemand = clampBody(desired - newHead)
        var newBody = behavior.bodyTarget + (bodyDemand - behavior.bodyTarget) * bodyRate
        if deltaTime > 0 {
            newBody = approach(current: behavior.bodyTarget,
                               target: newBody,
                               maxDelta: settings.bodyRateCapDegPerSec * deltaTime)
        }
        newBody = clampBody(newBody)

        // While tracking, gradually hand off head deflection to the body so the torso
        // orients toward the subject without moving the camera off-target.
        if context == .tracking {
            let headDeflection = abs(newHead)
            if headDeflection > 0.5 { // avoid tiny twitches
                let cameraTarget = desired
                let headRange = configuration.head.logicalRange
                let bodyRange = configuration.body.logicalRange
                let minBodyForCamera = max(bodyRange.lowerBound, cameraTarget - headRange.upperBound)
                let maxBodyForCamera = min(bodyRange.upperBound, cameraTarget - headRange.lowerBound)
                if minBodyForCamera <= maxBodyForCamera {
                    let recenterRange = minBodyForCamera...maxBodyForCamera
                    let preferredBody = recenterRange.clamp(cameraTarget)
                    let recenterRate = (params.bodyFollowRate * 0.5).clamped(to: 0.02...0.5)
                    var recenteredBody = newBody + (preferredBody - newBody) * recenterRate
                    if deltaTime > 0 {
                        recenteredBody = approach(current: newBody,
                                                  target: recenteredBody,
                                                  maxDelta: settings.bodyRateCapDegPerSec * deltaTime)
                    }
                    recenteredBody = clampBody(recenteredBody)
                    let compensatedHead = clampHead(cameraTarget - recenteredBody)
                    var recenteredHead = compensatedHead
                    if deltaTime > 0 {
                        recenteredHead = approach(current: newHead,
                                                  target: compensatedHead,
                                                  maxDelta: settings.headRateCapDegPerSec * deltaTime)
                    }
                    newBody = recenteredBody
                    newHead = recenteredHead
                }
            }
        }

        newHead = resolveStalledTarget(for: .head, proposed: newHead, now: now)
        newBody = resolveStalledTarget(for: .body, proposed: newBody, now: now)

        behavior.headTarget = newHead
        behavior.bodyTarget = newBody
    }

    private func resolveStalledTarget(for axis: ServoAxis, proposed: Double, now: Date) -> Double {
        switch axis {
        case .head:
            guard let guardConfig = configuration.head.stallGuard else { return proposed }
            return resolveStalledTarget(
                proposed: proposed,
                state: &headStall,
                config: guardConfig,
                logicalRange: configuration.head.logicalRange,
                now: now,
                label: "head"
            )
        case .body:
            guard let guardConfig = configuration.body.stallGuard else { return proposed }
            return resolveStalledTarget(
                proposed: proposed,
                state: &bodyStall,
                config: guardConfig,
                logicalRange: configuration.body.logicalRange,
                now: now,
                label: "body"
            )
        }
    }

    private func resolveStalledTarget(
        proposed: Double,
        state: inout ServoStallState,
        config: ServoChannelConfiguration.StallGuard,
        logicalRange: ClosedRange<Double>,
        now: Date,
        label: String
    ) -> Double {
        if let frozen = state.frozenTarget {
            if let edge = state.frozenEdge {
                let releasing: Bool
                switch edge {
                case .lower:
                    releasing = proposed > frozen + config.tolerance
                case .upper:
                    releasing = proposed < frozen - config.tolerance
                }
                if !releasing { return frozen }
            } else if abs(proposed - frozen) <= config.tolerance {
                return frozen
            }
            state.frozenTarget = nil
            state.frozenEdge = nil
        }

        if state.lastTarget.map({ abs($0 - proposed) > config.minMovement }) ?? true {
            state.lastTarget = proposed
            state.lastCommandAt = now
            state.lastMovementAt = now
        }

        guard let measurement = state.lastMeasurement,
              let measuredAt = state.lastMeasurementAt,
              let commandAt = state.lastCommandAt else {
            return proposed
        }

        guard measuredAt >= commandAt else { return proposed }

        let stableSince = state.lastMovementAt ?? commandAt
        guard now.timeIntervalSince(stableSince) >= config.holdDuration else { return proposed }
        guard abs(measurement - proposed) <= config.tolerance else { return proposed }

        var settled = measurement
        var backedOff = false
        var settledEdge: ServoStallState.Edge?
        if config.backoff > 0 {
            if measurement - logicalRange.lowerBound <= config.tolerance {
                settled = (logicalRange.lowerBound + config.backoff).clamped(to: logicalRange)
                backedOff = true
                settledEdge = .lower
            } else if logicalRange.upperBound - measurement <= config.tolerance {
                settled = (logicalRange.upperBound - config.backoff).clamped(to: logicalRange)
                backedOff = true
                settledEdge = .upper
            }
        }

        state.frozenTarget = settled
        state.frozenEdge = settledEdge
        state.lastTarget = settled
        logEvent("servo.settle", values: [
            "servo": label,
            "target": proposed,
            "settled": settled
        ])
        if backedOff {
            logState("servo.backoff", values: [
                "servo": label,
                "meas": measurement,
                "settled": settled
            ])
        }
        return settled
    }

    private func updateStallMeasurement(for axis: ServoAxis, value: Double, now: Date) {
        switch axis {
        case .head:
            guard let guardConfig = configuration.head.stallGuard else { return }
            if let last = headStall.lastMeasurement {
                if abs(value - last) > guardConfig.minMovement {
                    headStall.lastMovementAt = now
                }
            } else {
                headStall.lastMovementAt = now
            }
            headStall.lastMeasurement = value
            headStall.lastMeasurementAt = now
        case .body:
            guard let guardConfig = configuration.body.stallGuard else { return }
            if let last = bodyStall.lastMeasurement {
                if abs(value - last) > guardConfig.minMovement {
                    bodyStall.lastMovementAt = now
                }
            } else {
                bodyStall.lastMovementAt = now
            }
            bodyStall.lastMeasurement = value
            bodyStall.lastMeasurementAt = now
        }
    }
    
    private func orientationParameters(for context: OrientationContext) -> (headFollowRate: Double, bodyFollowRate: Double, headJitter: ClosedRange<Double>) {
        switch context {
        case .search:
            if case .patrol(let config) = behavior.idleBehavior {
                return (config.headFollowRate, config.bodyFollowRate, config.headJitterRange)
            }
            return (0.5, 0.15, 0...0)
        case .tracking, .manual:
            let t = configuration.trackingBehavior
            return (t.headFollowRate, t.bodyFollowRate, 0...0)
        }
    }
    
    /// Camera-space predictor with small, offset-scaled lead and a center hold.
    private func updateTrackingHeading(offset: Double, now: Date, currentHeading: Double) {
        let cfg = configuration.trackingBehavior
        let halfFOV = max(1.0, cfg.cameraHorizontalFOV / 2.0)

        // Save latest raw offset for gain scheduling and diagnostics
        behavior.faceOffset = offset
        behavior.lastFaceOffset = offset

        // Deadband: sustain focus without changing target when centered
        if abs(offset) < cfg.deadband, let keep = behavior.trackingHeading ?? behavior.faceHeading {
            behavior.focus(on: keep, now: now)
            // Start/extend center hold window for body freeze
            if behavior.centerHoldBegan == nil { behavior.centerHoldBegan = now }
            return
        } else {
            behavior.centerHoldBegan = nil
        }

        // Filter offset (EMA)
        var tr = behavior.tracker
        let dt = max(1.0/90.0, min(0.2, tr.lastUpdate.map { now.timeIntervalSince($0) } ?? configuration.loopInterval))
        let filtered: Double
        if let lastF = tr.lastFiltered {
            filtered = lastF + (offset - lastF) * settings.offsetLPFAlpha
        } else {
            filtered = offset
        }

        // Camera-space velocity (deg/s), clamped
        if let lastF = tr.lastFiltered {
            let rawVel = ((filtered - lastF) * halfFOV) / dt
            let alpha = max(0.05, min(0.95, 1 - cfg.predictionSmoothing))
            let vSmoothed = tr.velCamDegPerSec + (rawVel - tr.velCamDegPerSec) * alpha
            tr.velCamDegPerSec = max(-settings.velCapDegPerSec, min(settings.velCapDegPerSec, vSmoothed))
        } else {
            tr.velCamDegPerSec = 0
        }
        tr.lastFiltered = filtered
        tr.lastOffset = offset
        tr.lastUpdate = now
        behavior.tracker = tr

        // Measurement in absolute space
        let measAbs = clampCamera(currentHeading + filtered * halfFOV)

        // Reject big jumps vs last track to avoid bursts from detector swaps
        let prior = behavior.trackingHeading ?? behavior.faceHeading ?? measAbs
        if abs(measAbs - prior) > settings.maxJumpDeg {
            logEvent("tracking.reject", values: [
                "jump": abs(measAbs - prior),
                "meas": measAbs,
                "pred": prior
            ])
            // Keep focusing on prior target without accepting this jump
            behavior.focus(on: prior, now: now)
            return
        }

        // Lead term: tiny, scaled by |filtered offset|, zero near center
        let leadScale = min(1.0, max(0.0, abs(filtered))) // 0..1
        let leadTerm = max(-settings.leadDegCap, min(settings.leadDegCap, tr.velCamDegPerSec * (settings.leadSecondsMax * leadScale)))

        // Predicted absolute heading (bounded)
        let predictedAbs = clampCamera(currentHeading + filtered * halfFOV + leadTerm)

        behavior.faceHeading = measAbs

        // Blend prediction with measurement; near center trust measurement more
        let blend = settings.predictionBlendBase + settings.predictionBlendScale * leadScale
        let alphaPred = blend.clamped(to: 0...1)
        let blended = prior + (predictedAbs - prior) * alphaPred

        // Center-hold body freeze helper: if very centered & slow, keep heading steady
        if abs(filtered) < settings.centerHoldOffsetNorm,
           abs(tr.velCamDegPerSec) < settings.centerHoldVelDeg {
            if behavior.centerHoldBegan == nil { behavior.centerHoldBegan = now }
            if now.timeIntervalSince(behavior.centerHoldBegan ?? now) >= settings.centerHoldMin {
                // Stick to prior to avoid dithering
                behavior.trackingHeading = prior
                behavior.focus(on: prior, now: now)
                logEvent("tracking.update", values: [
                    "offset": offset,
                    "meas": measAbs,
                    "pred": prior,
                    "note": "center-hold"
                ])
                // logState("tracking.face", values: ["meas": measAbs, "pred": prior, "off": offset])
                return
            }
        } else {
            behavior.centerHoldBegan = nil
        }

        behavior.trackingHeading = blended
        behavior.focus(on: blended, now: now)

        logEvent("tracking.update", values: [
            "offset": offset,
            "meas": measAbs,
            "pred": blended
        ])
        // logState("tracking.face", values: ["meas": measAbs, "pred": blended, "off": offset])
    }
    
    private func configureInitialPatrolState(now: Date) {
        guard case .patrol(let config) = behavior.idleBehavior else {
            behavior.patrolState = PatrolState()
            behavior.bodyTarget = 0
            behavior.headTarget = 0
            behavior.desiredHeading = 0
            return
        }
        guard let state = initialPatrolState(for: config, now: now) else {
            behavior.patrolState = PatrolState()
            behavior.bodyTarget = 0
            behavior.headTarget = 0
            behavior.desiredHeading = 0
            return
        }
        behavior.patrolState = state
        let heading = state.currentHeading
        behavior.bodyTarget = heading
        behavior.headTarget = heading
        behavior.desiredHeading = heading
        logEvent("patrol.init", values: [
            "heading": heading,
            "next": state.nextSwitch.timeIntervalSince1970
        ])
        logState("patrol.target", values: ["heading": heading])
    }
    
    private func setLeftGesture(_ gesture: LeftHandGesture) {
        behavior.leftGesture = gesture
        
        // If manually requested to lower, interrupt autopilot
        if case .down = gesture {
            if behavior.leftHandAutoState != .lowered && behavior.leftHandAutoState != .lowering {
                behavior.leftHandAutoState = .lowering
                let minAngle = configuration.leftHand.logicalRange.lowerBound
                setLeftHandTarget(angle: minAngle, speed: settings.leftHandLowerSpeed)
                logState("leftHand.manualLower")
            }
        } else if case .up = gesture {
            // Manual raise request
            if behavior.leftHandAutoState == .lowered {
                let maxAngle = configuration.leftHand.logicalRange.upperBound
                setLeftHandTarget(angle: maxAngle, speed: settings.leftHandRaiseSpeed)
                logState("leftHand.manualRaise")
            }
        }
    }
    
    private var resolvedLeftHandCooldownDuration: TimeInterval {
        max(settings.minimumLeftHandCooldown, configuration.leftHandCooldownDuration)
    }
    
    private func resetLeftHandAutopilot(clearTimeCooldown: Bool = false) {
        behavior.leftHandAutoState = .lowered
        behavior.leftHandTargetAngle = nil
        behavior.leftHandRaisedTimestamp = nil
        behavior.leftHandPauseEndTime = nil
        behavior.leftHandCooldownActive = false
        behavior.leftHandAutopilotArmed = false
        if clearTimeCooldown { behavior.leftHandCooldownUntil = nil }
        setLeftGesture(.down)
    }
    
    private var leftHandTimeoutEnabled: Bool { settings.leftHandMaxRaisedDuration > 0 }
    
    private func isLeftHandTimeCooldownActive(now: Date) -> Bool {
        guard let until = behavior.leftHandCooldownUntil else {
            // No time-based cooldown, also clear the active flag
            behavior.leftHandCooldownActive = false
            return false
        }
        if now < until { return true }
        // Cooldown expired, clear both
        behavior.leftHandCooldownUntil = nil
        behavior.leftHandCooldownActive = false
        return false
    }

    private func armLeftHandAutopilotIfEligible(now: Date) {
        guard !isLeftHandTimeCooldownActive(now: now) else { return }
        behavior.leftHandAutopilotArmed = true
        logState("leftHand.armed")
    }

    private func startLeftHandCooldown(now: Date) {
        if let until = behavior.leftHandCooldownUntil, now < until { return }
        behavior.leftHandCooldownUntil = now + resolvedLeftHandCooldownDuration
    }

    private func enterLeftHandCooldown(now: Date) {
        behavior.leftHandCooldownActive = true
        behavior.leftHandAutoState = .lowered
        behavior.leftHandTargetAngle = nil
        behavior.leftHandRaisedTimestamp = nil
        behavior.leftHandPauseEndTime = nil
        startLeftHandCooldown(now: now)
        setLeftGesture(.down)
        behavior.leftHandAutopilotArmed = false
        logState("leftHand.cooldown")
    }

    private func setLeftHandTarget(angle: Double, speed: Double) {
        behavior.leftHandTargetAngle = angle
        behavior.leftHandLastLoggedAngle = nil  // Reset so first position update gets logged
        leftHandDriver.setVelocity(speed)
        leftHandDriver.move(toLogical: angle)
        logState("leftHand.target", values: ["angle": angle, "speed": speed])
    }

    private func hasReachedTarget(measured: Double, target: Double) -> Bool {
        abs(measured - target) <= settings.leftHandPositionTolerance
    }

    private func handleLeftHandPositionUpdate(angle: Double, now: Date) {
        guard let target = behavior.leftHandTargetAngle else { return }
        
        // Log intermediate positions during movement (every 0.1 change)
        let logThreshold = 0.1
        if behavior.leftHandAutoState != .lowered && behavior.leftHandAutoState != .pausingAtTop {
            if let lastLogged = behavior.leftHandLastLoggedAngle {
                if abs(angle - lastLogged) >= logThreshold {
                    logState("leftHand.position", values: ["angle": String(format: "%.2f", angle)])
                    behavior.leftHandLastLoggedAngle = angle
                }
            } else {
                logState("leftHand.position", values: ["angle": String(format: "%.2f", angle)])
                behavior.leftHandLastLoggedAngle = angle
            }
        }
        
        if hasReachedTarget(measured: angle, target: target) {
            switch behavior.leftHandAutoState {
            case .raising:
                logState("leftHand.reached", values: ["angle": angle])
                // Start waving
                let cycles = max(1, settings.leftHandWaveCycles)
                behavior.leftHandAutoState = .waving(cyclesRemaining: cycles, phase: .movingDown)
                let maxAngle = configuration.leftHand.logicalRange.upperBound
                let waveTarget = maxAngle - settings.leftHandWaveBackAngle
                setLeftHandTarget(angle: waveTarget, speed: settings.leftHandWaveSpeed)
                logState("leftHand.startWaving", values: ["cycles": cycles])
                
            case .waving(let cyclesRemaining, let phase):
                logState("leftHand.reached", values: ["angle": angle])
                let maxAngle = configuration.leftHand.logicalRange.upperBound
                let waveTarget = maxAngle - settings.leftHandWaveBackAngle
                
                switch phase {
                case .movingDown:
                    // Move back up
                    behavior.leftHandAutoState = .waving(cyclesRemaining: cyclesRemaining, phase: .movingUp)
                    setLeftHandTarget(angle: maxAngle, speed: settings.leftHandWaveSpeed)
                    
                case .movingUp:
                    let newCyclesRemaining = cyclesRemaining - 1
                    if newCyclesRemaining > 0 {
                        // Continue waving - move down again
                        behavior.leftHandAutoState = .waving(cyclesRemaining: newCyclesRemaining, phase: .movingDown)
                        setLeftHandTarget(angle: waveTarget, speed: settings.leftHandWaveSpeed)
                    } else {
                        // Waving complete, pause at top
                        behavior.leftHandAutoState = .pausingAtTop
                        behavior.leftHandPauseEndTime = now + settings.leftHandPauseDuration
                        logState("leftHand.pauseAtTop", values: ["duration": settings.leftHandPauseDuration])
                    }
                }
                
            case .lowering:
                logState("leftHand.reached", values: ["angle": angle])
                // Reached lowered position
                enterLeftHandCooldown(now: now)
                
            default:
                break
            }
        }
    }
    
    private func updateLeftHandAutopilot(now: Date) {
        let trackingActive = (behavior.focusStart != nil)
        
        // If not tracking, ensure hand is lowered
        guard trackingActive else {
            let minAngle = configuration.leftHand.logicalRange.lowerBound
            if behavior.leftHandAutoState != .lowered || behavior.leftHandCooldownActive {
                // Start lowering if not already lowered
                if behavior.leftHandAutoState != .lowered && behavior.leftHandAutoState != .lowering {
                    behavior.leftHandAutoState = .lowering
                    setLeftHandTarget(angle: minAngle, speed: settings.leftHandLowerSpeed)
                    logState("leftHand.loweringDueToTrackingloss")
                }
            }
            return
        }
        
        // Check if autopilot is engaged
        let autopilotEngaged = behavior.leftHandAutopilotArmed || behavior.leftHandAutoState != .lowered
        guard autopilotEngaged else { return }
        
        if isLeftHandTimeCooldownActive(now: now) { return }
        
        // Check max raised duration timeout
        if leftHandTimeoutEnabled,
           behavior.leftHandAutoState != .lowered,
           let start = behavior.leftHandRaisedTimestamp,
           now.timeIntervalSince(start) >= settings.leftHandMaxRaisedDuration {
            behavior.leftHandAutoState = .lowering
            let minAngle = configuration.leftHand.logicalRange.lowerBound
            setLeftHandTarget(angle: minAngle, speed: settings.leftHandLowerSpeed)
            logState("leftHand.loweringDueToTimeout")
            return
        }
        
        switch behavior.leftHandAutoState {
        case .lowered:
            guard behavior.leftHandAutopilotArmed else { return }
            behavior.leftHandAutopilotArmed = false
            behavior.leftHandAutoState = .raising
            behavior.leftHandRaisedTimestamp = now
            let maxAngle = configuration.leftHand.logicalRange.upperBound
            setLeftHandTarget(angle: maxAngle, speed: settings.leftHandRaiseSpeed)
            setLeftGesture(.up)
            logState("leftHand.raising")
            
        case .raising:
            // Waiting for servo to reach top position
            // Position observer will trigger state transition
            break
            
        case .waving:
            // Waiting for servo to reach wave position
            // Position observer handles state transitions
            break
            
        case .pausingAtTop:
            // Check if pause is complete
            guard let pauseEnd = behavior.leftHandPauseEndTime else { return }
            if now >= pauseEnd {
                behavior.leftHandPauseEndTime = nil
                behavior.leftHandAutoState = .lowering
                let minAngle = configuration.leftHand.logicalRange.lowerBound
                setLeftHandTarget(angle: minAngle, speed: settings.leftHandLowerSpeed)
                logState("leftHand.lowering")
            }
            
        case .lowering:
            // Waiting for servo to reach bottom position
            // Position observer will handle transition to cooldown
            break
        }
    }
    
    private func leftHandValue(deltaTime: TimeInterval) -> Double {
        // Return the actual measured position if available (for smooth animation)
        if let measured = behavior.leftHandMeasuredAngle {
            return measured
        }
        // Fallback to gesture-based values
        switch behavior.leftGesture {
        case .down:
            return configuration.leftHand.logicalRange.lowerBound
        case .up:
            return configuration.leftHand.logicalRange.upperBound
        case .wave:
            // Wave gesture is no longer used - handled by state machine
            return configuration.leftHand.logicalRange.upperBound
        }
    }
    
    private func rightHandValue() -> Double {
        let range = configuration.rightHand.logicalRange
        switch behavior.rightGesture {
        case .down: return range.lowerBound
        case .point: return range.lowerBound + range.span * 0.5
        case .emphasise: return range.upperBound
        }
    }
    
    private func applyPose() {
        bodyDriver.move(toLogical: pose.bodyAngle)
        headDriver.move(toLogical: pose.headAngle)
        // Only apply left hand pose if autopilot is not actively controlling it
        if behavior.leftHandAutoState == .lowered && behavior.leftHandTargetAngle == nil {
            leftHandDriver.move(toLogical: pose.leftHand)
        }
        rightHandDriver.move(toLogical: pose.rightHand)
    }
    
    private func clampCamera(_ heading: Double) -> Double { configuration.cameraRange.clamp(heading) }
    private func clampBody(_ angle: Double) -> Double { configuration.body.logicalRange.clamp(angle) }
    private func clampHead(_ angle: Double) -> Double { configuration.head.logicalRange.clamp(angle) }

    private func approach(current: Double, target: Double, maxDelta: Double) -> Double {
        if target > current { return min(target, current + maxDelta) }
        else { return max(target, current - maxDelta) }
    }

    private func syncOnWorkerQueue<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: workerQueueKey) != nil { return work() }
        return workerQueue.sync(execute: work)
    }
    
    private func telemetryPayload(from values: [String: CustomStringConvertible]) -> [String: Any]? {
        var payload: [String: Any] = ["ts": Date().timeIntervalSince1970]
        for (key, value) in values {
            if let double = value as? Double { payload[key] = double }
            else if let int = value as? Int { payload[key] = int }
            else if let bool = value as? Bool { payload[key] = bool }
            else { payload[key] = value.description }
        }
        return payload
    }
    
    private func logEvent(_ type: String, values: [String: CustomStringConvertible] = [:]) {
        guard loggingEnabled else { return }
        var payload: [String: CustomStringConvertible] = ["type": type]
        for (k, v) in values { payload[k] = v }
        if let common = telemetryPayload(from: payload), let json = telemetry.serialize(common) {
            telemetry.write(line: json)
        }
    }

    private func logState(_ label: String, values: [String: CustomStringConvertible] = [:]) {
        guard loggingEnabled else { return }
        let timestamp = String(format: "%.3f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
        var message = "[\(timestamp)] [state] \(label)"
        if !values.isEmpty {
            let details = values.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            message += " " + details
        }
        print(message)
    }
    
    private func contextName(_ context: OrientationContext) -> String {
        switch context {
        case .manual:   return "manual"
        case .tracking: return "tracking"
        case .search:   return "search"
        }
    }

    private func teardownDriversLocked() {
        leftHandDriver.shutdown()
        rightHandDriver.shutdown()
        headDriver.shutdown()
        bodyDriver.shutdown()
    }
}

// MARK: - Utils

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

private func lerp(_ start: Double, _ end: Double, t: Double) -> Double { start + (end - start) * t }
