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
    }
    
    enum FigurineError: Error {
        case alreadyRunning
        case attachmentTimeout(channel: Int)
    }
    
    private enum OrientationContext { case search, tracking, manual }
    private enum LeftHandAutoState { case lowered, raising, waving, pulseBack, pulseForward, raised }
    
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
        var leftHandWaveReadyAt: Date?
        var leftHandWaveEndAt: Date?
        var leftHandPulseEndAt: Date?
        var leftHandOverride: Double?
        var leftHandRaisedTimestamp: Date?
        var leftHandCooldownActive = false
        var leftHandCooldownUntil: Date?
        var leftHandAutopilotArmed = false

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
    private let leftHandChannel: ServoChannel
    private let rightHandChannel: ServoChannel
    private let headChannel: ServoChannel
    private let bodyChannel: ServoChannel
    private let settings: Settings
    private let loggingEnabled: Bool
    private let workerQueue = DispatchQueue(label: "RoboSanta.StateMachine", qos: .userInitiated)
    private let workerQueueKey = DispatchSpecificKey<Void>()
    
    private var pendingEvents: [Event] = []
    private var behavior: BehaviorState
    private var pose = FigurinePose()
    private var measuredBodyAngle: Double?
    private var measuredHeadAngle: Double?
    private var loopTask: Task<Void, Never>?
    private var lastUpdate = Date()
    private var leftWavePhase: Double = 0
    private var idlePhase: Double = 0
    private var leftIsWaving = false
    private var isRunning = false
    
    init(configuration: FigurineConfiguration = .default, telemetry: TelemetryLogger = .shared, settings: Settings = .default) {
        let mergedSettings = settings.withFigurineConfiguration(configuration)
        self.settings = mergedSettings
        self.configuration = mergedSettings.figurineConfiguration
        self.telemetry = telemetry
        self.loggingEnabled = mergedSettings.loggingEnabled
        self.behavior = BehaviorState(idleBehavior: self.configuration.idleBehavior)
        self.leftHandChannel = ServoChannel(configuration: self.configuration.leftHand)
        self.rightHandChannel = ServoChannel(configuration: self.configuration.rightHand)
        self.headChannel = ServoChannel(configuration: self.configuration.head)
        self.bodyChannel = ServoChannel(configuration: self.configuration.body)
        let telemetry: (String, [String: CustomStringConvertible]) -> Void = { [weak self] event, values in
            self?.logEvent(event, values: values)
        }
        leftHandChannel.setTelemetryLogger(telemetry)
        rightHandChannel.setTelemetryLogger(telemetry)
        headChannel.setTelemetryLogger(telemetry)
        bodyChannel.setTelemetryLogger(telemetry)
        bodyChannel.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async { self.measuredBodyAngle = angle }
        }
        headChannel.setPositionObserver { [weak self] angle in
            guard let self else { return }
            self.workerQueue.async { self.measuredHeadAngle = angle }
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
        if let task { await task.value }
        syncOnWorkerQueue {
            pendingEvents.removeAll(keepingCapacity: true)
            resetLeftHandAutopilot(clearTimeCooldown: true)
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
                behavior.clearFocus()
                if hadFocus { startLeftHandCooldown(now: now) }
                resetLeftHandAutopilot()
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
        updateHeadAndBodyTargets(deltaTime: deltaTime)

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
            switch context {
            case .tracking: logState("mode.tracking")
            case .search:   logState("mode.search")
            case .manual:   logState("mode.manual")
            }
        }
    }
    
    private func updateHeadAndBodyTargets(deltaTime: TimeInterval) {
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
                logState("tracking.face", values: ["meas": measAbs, "pred": prior, "off": offset])
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
        logState("tracking.face", values: ["meas": measAbs, "pred": blended, "off": offset])
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
        let wasWave = leftIsWaving
        behavior.leftGesture = gesture
        behavior.leftHandOverride = nil
        if case .wave = gesture {
            if !wasWave { leftWavePhase = 0 }
            leftIsWaving = true
        } else {
            leftIsWaving = false
        }
    }
    
    private var resolvedLeftHandCooldownDuration: TimeInterval {
        max(settings.minimumLeftHandCooldown, configuration.leftHandCooldownDuration)
    }
    
    private func resetLeftHandAutopilot(clearTimeCooldown: Bool = false) {
        behavior.leftHandAutoState = .lowered
        behavior.leftHandWaveReadyAt = nil
        behavior.leftHandWaveEndAt = nil
        behavior.leftHandPulseEndAt = nil
        behavior.leftHandOverride = nil
        behavior.leftHandRaisedTimestamp = nil
        behavior.leftHandCooldownActive = false
        behavior.leftHandAutopilotArmed = false
        if clearTimeCooldown { behavior.leftHandCooldownUntil = nil }
        setLeftGesture(.down)
    }
    
    private var leftHandPulseEnabled: Bool {
        sanitizedLeftHandPulseBackDelta > 0 || sanitizedLeftHandPulseForwardDelta > 0
    }
    
    private var sanitizedLeftHandPulseBackDelta: Double { max(0, settings.leftHandPulseBackDelta) }
    private var sanitizedLeftHandPulseForwardDelta: Double { max(0, settings.leftHandPulseForwardDelta) }
    private var leftHandTimeoutEnabled: Bool { settings.leftHandMaxRaisedDuration > 0 }
    private func isLeftHandTimeCooldownActive(now: Date) -> Bool {
        guard let until = behavior.leftHandCooldownUntil else { return false }
        if now < until { return true }
        behavior.leftHandCooldownUntil = nil
        return false
    }
    
    private func setLeftHandOverride(toNormalized value: Double?) {
        if let value {
            behavior.leftHandOverride = configuration.leftHand.logicalRange.clamp(value)
        } else {
            behavior.leftHandOverride = nil
        }
    }

    private func applyLeftHandPulse(offset: Double) {
        guard leftHandPulseEnabled else {
            setLeftHandOverride(toNormalized: nil)
            return
        }
        let top = configuration.leftHand.logicalRange.upperBound
        setLeftHandOverride(toNormalized: top + offset)
    }

    private func armLeftHandAutopilotIfEligible(now: Date) {
        guard !behavior.leftHandCooldownActive else { return }
        guard !isLeftHandTimeCooldownActive(now: now) else { return }
        behavior.leftHandAutopilotArmed = true
    }

    private func startLeftHandCooldown(now: Date) {
        if let until = behavior.leftHandCooldownUntil, now < until { return }
        behavior.leftHandCooldownUntil = now + resolvedLeftHandCooldownDuration
    }

    private func enterLeftHandCooldown(now: Date) {
        behavior.leftHandCooldownActive = true
        behavior.leftHandAutoState = .lowered
        behavior.leftHandWaveReadyAt = nil
        behavior.leftHandWaveEndAt = nil
        behavior.leftHandPulseEndAt = nil
        behavior.leftHandRaisedTimestamp = nil
        startLeftHandCooldown(now: now)
        setLeftHandOverride(toNormalized: nil)
        setLeftGesture(.down)
        behavior.leftHandAutopilotArmed = false
    }

    private func startLeftHandPulseBack(now: Date) {
        setLeftGesture(.up)
        behavior.leftHandPulseEndAt = now + settings.leftHandPulseDuration
        applyLeftHandPulse(offset: -sanitizedLeftHandPulseBackDelta)
    }

    private func startLeftHandPulseForward(now: Date) {
        setLeftGesture(.up)
        behavior.leftHandPulseEndAt = now + settings.leftHandPulseDuration
        applyLeftHandPulse(offset: sanitizedLeftHandPulseForwardDelta)
    }
    
    private func updateLeftHandAutopilot(now: Date) {
        let trackingActive = (behavior.focusStart != nil)
        guard trackingActive else {
            if behavior.leftHandAutoState != .lowered || behavior.leftHandCooldownActive {
                resetLeftHandAutopilot()
            }
            return
        }
        let autopilotEngaged = behavior.leftHandAutopilotArmed || behavior.leftHandAutoState != .lowered
        guard autopilotEngaged else { return }
        if isLeftHandTimeCooldownActive(now: now) { return }
        if behavior.leftHandCooldownActive { return }
        if leftHandTimeoutEnabled,
           behavior.leftHandAutoState != .lowered,
           let start = behavior.leftHandRaisedTimestamp,
           now.timeIntervalSince(start) >= settings.leftHandMaxRaisedDuration {
            enterLeftHandCooldown(now: now)
            return
        }
        switch behavior.leftHandAutoState {
        case .lowered:
            guard behavior.leftHandAutopilotArmed else { return }
            behavior.leftHandAutopilotArmed = false
            behavior.leftHandAutoState = .raising
            behavior.leftHandWaveReadyAt = now + settings.leftHandRaiseDelay
            behavior.leftHandWaveEndAt = nil
            behavior.leftHandPulseEndAt = nil
            behavior.leftHandRaisedTimestamp = now
            setLeftGesture(.up)
        case .raising:
            guard let ready = behavior.leftHandWaveReadyAt else { return }
            if now >= ready {
                behavior.leftHandAutoState = .waving
                behavior.leftHandWaveReadyAt = nil
                behavior.leftHandWaveEndAt = now + settings.leftHandWaveDuration
                setLeftGesture(.wave(amplitude: settings.leftHandWaveAmplitude, speed: settings.leftHandWaveSpeed))
            }
        case .waving:
            guard let end = behavior.leftHandWaveEndAt else { return }
            if now >= end {
                behavior.leftHandWaveEndAt = nil
                if leftHandPulseEnabled {
                    behavior.leftHandAutoState = .pulseBack
                    startLeftHandPulseBack(now: now)
                } else {
                    behavior.leftHandAutoState = .raised
                    setLeftHandOverride(toNormalized: nil)
                    setLeftGesture(.up)
                }
            }
        case .pulseBack:
            guard let end = behavior.leftHandPulseEndAt else { return }
            if now >= end {
                behavior.leftHandPulseEndAt = nil
                if sanitizedLeftHandPulseForwardDelta > 0 {
                    behavior.leftHandAutoState = .pulseForward
                    startLeftHandPulseForward(now: now)
                } else {
                    behavior.leftHandAutoState = .raised
                    setLeftHandOverride(toNormalized: nil)
                    setLeftGesture(.up)
                }
            }
        case .pulseForward:
            guard let end = behavior.leftHandPulseEndAt else { return }
            if now >= end {
                behavior.leftHandPulseEndAt = nil
                behavior.leftHandAutoState = .raised
                setLeftHandOverride(toNormalized: nil)
                setLeftGesture(.up)
            }
        case .raised:
            break
        }
    }
    
    private func leftHandValue(deltaTime: TimeInterval) -> Double {
        if let override = behavior.leftHandOverride {
            return override
        }
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
        case .down: return range.lowerBound
        case .point: return range.lowerBound + range.span * 0.5
        case .emphasise: return range.upperBound
        }
    }
    
    private func applyPose() {
        bodyChannel.move(toLogical: pose.bodyAngle)
        headChannel.move(toLogical: pose.headAngle)
        leftHandChannel.move(toLogical: pose.leftHand)
        rightHandChannel.move(toLogical: pose.rightHand)
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
        var message = "[state] \(label)"
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

    private func teardownChannelsLocked() {
        leftHandChannel.shutdown()
        rightHandChannel.shutdown()
        headChannel.shutdown()
        bodyChannel.shutdown()
    }
}

private extension StateMachine.LeftHandGesture {
    var isWave: Bool {
        if case .wave = self { return true }
        return false
    }
}

// MARK: - Servo wrapper

private final class ServoChannel {
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
        catch { print(error); throw error }
    }
    
    private func perform(_ step: String, _ action: () throws -> Void) {
        do { try action() }
        catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            logTelemetry("servo.error", values: ["step": step, "code": err.errorCode.rawValue, "description": err.description])
        }
        catch { print(error) }
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
