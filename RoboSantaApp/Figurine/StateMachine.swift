// StateMachine.swift
//
// Clean, oscillation‑resistant state machine for RoboSanta.
// - Single source of truth: desired camera heading.
// - Decoupled head/body solution (head leads, body follows).
// - α‑β (g‑h) filter for face heading + short lead prediction.
// - Measurement gating to avoid rapid target switching with multiple faces.
// - Deadband on visual error to avoid micro‑chatter.
// - High‑signal telemetry + succinct stdout state markers.

import Foundation
import Dispatch

/// Drives the physical figurine by coordinating the four Phidget RC servos.
/// Feed it `Event`s from the outside world (e.g. from CameraManager).
final class StateMachine {

    // MARK: - Public API

    enum Event: Equatable {
        case idle
        case aimCamera(Double)                // absolute degrees, camera-forward = 0
        case clearTarget
        case setLeftHand(LeftHandGesture)
        case setRightHand(RightHandGesture)
        case setIdleBehavior(IdleBehavior)
        case personDetected(relativeOffset: Double) // [-1, 1], -1=far left, +1=far right
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
            let headings: [Double]                       // absolute headings (deg)
            let intervalRange: ClosedRange<TimeInterval> // dwell between transitions
            let transitionDurationRange: ClosedRange<TimeInterval>
            let headFollowRate: Double
            let bodyFollowRate: Double
            let headJitterRange: ClosedRange<Double>     // small random head jitter in search
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
        let headContributionRatio: Double     // not used for splitting; kept for compatibility
        let loopInterval: TimeInterval
        let attachmentTimeout: TimeInterval

        /// Valid absolute range for the camera (body + head).
        var cameraRange: ClosedRange<Double> {
            (body.logicalRange.lowerBound + head.logicalRange.lowerBound)...(body.logicalRange.upperBound + head.logicalRange.upperBound)
        }

        struct TrackingBehavior {
            let holdDuration: TimeInterval
            let headFollowRate: Double         // [0, 1] per tick blending for head
            let bodyFollowRate: Double         // [0, 1] per tick blending for body
            let cameraHorizontalFOV: Double    // degrees
            let deadband: Double               // fraction of half‑FOV, e.g. 0.08 => ~2.4° at 60° FOV
            let predictionSmoothing: Double    // in [0, 0.95] -> converted to α for α‑β filter
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

    // MARK: - Internal model

    private enum OrientationContext { case search, tracking, manual }

    private struct PatrolState {
        var headingIndex: Int = 0
        var currentHeading: Double = 0
        var startHeading: Double = 0
        var targetHeading: Double = 0
        var nextSwitch: Date = .distantPast
        var transitionStart: Date = .distantPast
        var transitionEnd: Date = .distantPast
    }

    /// α‑β (g‑h) filter for heading with a tiny lead prediction.
    private struct AlphaBetaFilter {
        // Estimates
        var x: Double = 0      // heading (deg)
        var v: Double = 0      // angular velocity (deg/s)
        // Gains
        var alpha: Double      // typically ~0.6..0.85  (higher -> more responsive)
        var beta: Double       // typically ~0.1..0.5   (velocity gain, scaled by dt)
        // Time
        private var lastT: Date?

        init(alpha: Double, beta: Double) {
            self.alpha = alpha.clamped(to: 0.01...0.99)
            self.beta  = beta.clamped(to: 0.01...1.0)
        }

        mutating func reset(to measurement: Double, now: Date) {
            x = measurement
            v = 0
            lastT = now
        }

        mutating func update(measurement z: Double, now: Date) {
            let t = now
            let dt = max(0.005, min(0.1, (lastT.map { t.timeIntervalSince($0) } ?? 0.02)))
            lastT = t

            // Predict
            let xPred = x + v * dt
            let vPred = v

            // Innovate
            let r = z - xPred

            // Update
            x = xPred + alpha * r
            v = vPred + (beta * r) / dt
        }

        func predict(leadSeconds: TimeInterval) -> Double { x + v * leadSeconds }
    }

    private struct BehaviorState {
        var idleBehavior: IdleBehavior
        var leftGesture: LeftHandGesture = .down
        var rightGesture: RightHandGesture = .down

        // Orientation state
        var currentContext: OrientationContext = .search
        var desiredCameraHeading: Double = 0          // single source of truth

        // Head/body internal targets
        var bodyTarget: Double = 0
        var headTarget: Double = 0

        // Manual override
        var manualHeading: Double?
        var manualOverride = false

        // Patrol
        var patrol = PatrolState()

        // Tracking
        var lastPersonDetection: Date?
        var focusStart: Date?
        var faceOffset: Double?                       // last normalized offset [-1, 1]
        var tracker: AlphaBetaFilter?                 // α‑β filter instance
        var headJitterOffset: Double = 0              // small search jitter (deg)

        mutating func focus(now: Date) {
            lastPersonDetection = now
            focusStart = focusStart ?? now
        }

        mutating func clearFocus() {
            lastPersonDetection = nil
            focusStart = nil
            faceOffset = nil
            tracker = nil
        }

        func personStillHeld(now: Date, hold: TimeInterval) -> Bool {
            guard let last = lastPersonDetection else { return false }
            return now.timeIntervalSince(last) <= hold
        }
    }

    // MARK: - Instance wiring

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

    // Tracking tuning (derived from config, set when starting)
    private var gatingDegrees: Double = 18           // max measurement jump accepted
    private var deadbandDegrees: Double = 2.4        // ignore tiny errors
    private let predictionLead: TimeInterval = 0.25  // small look‑ahead
    private var alphaBeta: (alpha: Double, beta: Double) = (0.7, 0.25)

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
        deriveTrackingTuning()
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

                loopTask = Task { await self.runLoop() }
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
    func cameraHeading() -> Double { syncOnWorkerQueue { pose.cameraHeading } }

    // MARK: - Loop

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

    // MARK: - Event handling

    private func processEvents(now: Date) {
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)

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
                behavior.currentContext = .manual
                logState("mode.manual", values: ["target": behavior.manualHeading ?? 0])

            case .clearTarget:
                behavior.manualOverride = false
                behavior.manualHeading = nil
                logState("manual.clear")

            case .setLeftHand(let gesture):
                let wasWaving = leftIsWaving
                behavior.leftGesture = gesture
                if case .wave = gesture {
                    if !wasWaving { leftWavePhase = 0 }
                    leftIsWaving = true
                } else { leftIsWaving = false }

            case .setRightHand(let gesture):
                behavior.rightGesture = gesture

            case .setIdleBehavior(let newBehavior):
                behavior.idleBehavior = newBehavior
                idlePhase = 0
                configureInitialPatrolState(now: now)
                logState("idle.behavior", values: ["kind": "\(newBehavior)"])

            case .personDetected(let offset):
                // Update tracking from a single normalized horizontal offset.
                updateTrackingHeading(offset: offset, now: now, currentHeading: pose.cameraHeading)

            case .personLost:
                behavior.lastPersonDetection = nil
                logEvent("tracking.lost")
                logState("tracking.lost")
            }
        }
    }

    // MARK: - Core update

    private func updatePose(now: Date, deltaTime: TimeInterval) {
        // Decide desired absolute camera heading and context.
        decideDesiredHeading(now: now, deltaTime: deltaTime)

        // Compute head/body targets from desired camera heading with decoupled filters.
        let params = orientationParameters(for: behavior.currentContext)

        // 1) Body slowly follows desired camera heading (LPF).
        let bodyDemand = clampBody(behavior.desiredCameraHeading)
        behavior.bodyTarget = clampBody(behavior.bodyTarget + (bodyDemand - behavior.bodyTarget) * params.bodyFollowRate.clamped(to: 0...1))

        // 2) Head leads: aim at what's left after body contribution (+ optional search jitter).
        let jitter = (behavior.currentContext == .search) ? behavior.headJitterOffset : 0
        let headDemandRaw = clampHead(behavior.desiredCameraHeading - behavior.bodyTarget + jitter)
        behavior.headTarget = clampHead(behavior.headTarget + (headDemandRaw - behavior.headTarget) * params.headFollowRate.clamped(to: 0...1))

        // 3) Publish pose
        pose.bodyAngle = behavior.bodyTarget
        pose.headAngle = behavior.headTarget
        pose.leftHand  = leftHandValue(deltaTime: deltaTime)
        pose.rightHand = rightHandValue()

        // Occasional telemetry of full pose & estimates (lightweight)
        if Int(now.timeIntervalSince1970 * 5) % 5 == 0 { // ~1 Hz
            logEvent("loop.pose", values: [
                "ctx": contextName(behavior.currentContext),
                "cam.des": behavior.desiredCameraHeading,
                "body.tgt": behavior.bodyTarget,
                "head.tgt": behavior.headTarget
            ])
        }
    }

    /// Decide desired camera heading based on manual override, tracking hold, or idle search.
    private func decideDesiredHeading(now: Date, deltaTime: TimeInterval) {
        // Manual always wins
        if behavior.manualOverride, let manual = behavior.manualHeading {
            behavior.currentContext = .manual
            behavior.desiredCameraHeading = clampCamera(manual)
            return
        }

        // Tracking: if we recently saw a face, keep following predicted track
        if behavior.personStillHeld(now: now, hold: configuration.trackingBehavior.holdDuration),
           let tracker = behavior.tracker {
            behavior.currentContext = .tracking

            // Predict slightly ahead to reduce latency (keeps face inside frame)
            var predicted = tracker.predict(leadSeconds: predictionLead)
            predicted = clampCamera(predicted)

            // Apply small deadband on the *visual* error if we still have a measured offset.
            if let off = behavior.faceOffset {
                let needed = abs(off) * (configuration.trackingBehavior.cameraHorizontalFOV / 2)
                if needed < deadbandDegrees {
                    // within deadband: don't chase noise; keep previous desired heading
                    // (but still let body slowly pick up because desired is already close)
                } else {
                    behavior.desiredCameraHeading = predicted
                }
            } else {
                behavior.desiredCameraHeading = predicted
            }
            return
        } else {
            // If hold expired, drop focus entirely
            if let last = behavior.lastPersonDetection,
               now.timeIntervalSince(last) > configuration.trackingBehavior.holdDuration {
                behavior.clearFocus()
                logState("tracking.clear")
            }
        }

        // Search / idle
        behavior.currentContext = .search
        behavior.desiredCameraHeading = clampCamera(idleHeading(now: now, deltaTime: deltaTime))
    }

    // MARK: - Idle/search behaviors

    private func idleHeading(now: Date, deltaTime: TimeInterval) -> Double {
        switch behavior.idleBehavior {
        case .none:
            behavior.headJitterOffset = 0
            return 0

        case .sweep(let range, let period):
            let span = max(period, 0.1)
            idlePhase = (idlePhase + deltaTime * (2 * .pi / span)).truncatingRemainder(dividingBy: 2 * .pi)
            behavior.headJitterOffset = 0.0
            let center = range.midPoint
            let amplitude = range.span / 2
            return center + sin(idlePhase) * amplitude

        case .patrol(let cfg):
            guard !cfg.headings.isEmpty else { return 0 }
            var ps = behavior.patrol

            if now >= ps.nextSwitch {
                ps.headingIndex = (ps.headingIndex + 1) % cfg.headings.count
                ps.startHeading = ps.currentHeading
                ps.targetHeading = cfg.headings[ps.headingIndex]
                ps.transitionStart = now
                ps.transitionEnd = now + randomInterval(in: cfg.transitionDurationRange)
                ps.nextSwitch = ps.transitionEnd + randomInterval(in: cfg.intervalRange)

                // Randomize tiny search jitter for the head while patrolling
                behavior.headJitterOffset = randomValue(in: cfg.headJitterRange) * 0.1

                logEvent("patrol.transition", values: [
                    "target": ps.targetHeading,
                    "duration": ps.transitionEnd.timeIntervalSince(ps.transitionStart),
                    "next": ps.nextSwitch.timeIntervalSince1970
                ])
                logState("patrol.target", values: ["heading": ps.targetHeading])
            }

            if ps.transitionEnd > ps.transitionStart, now < ps.transitionEnd {
                let dur = max(0.001, ps.transitionEnd.timeIntervalSince(ps.transitionStart))
                let t = (now.timeIntervalSince(ps.transitionStart) / dur).clamped(to: 0...1)
                ps.currentHeading = lerp(ps.startHeading, ps.targetHeading, t: t)
            } else {
                ps.currentHeading = ps.targetHeading
            }

            behavior.patrol = ps
            return ps.currentHeading
        }
    }

    // MARK: - Tracking update from CameraManager

    private func updateTrackingHeading(offset: Double, now: Date, currentHeading: Double) {
        let cfg = configuration.trackingBehavior
        let halfFOV = max(1.0, cfg.cameraHorizontalFOV / 2)
        let measured = clampCamera(currentHeading + offset * halfFOV) // absolute degrees

        // Initialize or update α‑β filter (gated).
        if behavior.tracker == nil {
            // Map smoothing ∈ [0,0.95] → α,β (empirical: α=[0.6..0.85], β related)
            let alpha = max(0.4, min(0.9, 1.0 - cfg.predictionSmoothing)) // 0.7 by default
            let beta  = max(0.1, min(0.6, alpha * alpha * 0.5))           // ~0.245 by default
            behavior.tracker = AlphaBetaFilter(alpha: alpha, beta: beta)
            behavior.tracker?.reset(to: measured, now: now)
            deriveTrackingTuning() // refresh deadband/gating from FOV
            logEvent("tracking.init", values: ["meas": measured, "alpha": alpha, "beta": beta])
            logState("tracking.init", values: ["heading": measured])
        } else {
            // Gating: reject sudden large jumps (likely another face)
            let predicted = behavior.tracker!.predict(leadSeconds: 0)
            let jump = abs(angleDiff(predicted, measured))
            if jump > gatingDegrees {
                logEvent("tracking.reject", values: ["meas": measured, "pred": predicted, "jump": jump])
                // keep previous track; do not reset last detection time here (no "hold" refresh)
            } else {
                behavior.tracker?.update(measurement: measured, now: now)
                behavior.faceOffset = offset
                behavior.focus(now: now)
                let est = behavior.tracker!.x
                let vel = behavior.tracker!.v
                let pred = behavior.tracker!.predict(leadSeconds: predictionLead)
                logEvent("tracking.update", values: [
                    "offset": offset,
                    "meas": measured,
                    "est": est,
                    "vel": vel,
                    "pred": pred
                ])
                logState("tracking.face", values: ["meas": measured, "pred": pred, "off": offset])
            }
        }

        // If inside hard deadband, do not move desired heading this tick (but keep tracking alive).
        if abs(offset) < cfg.deadband {
            behavior.focus(now: now)
            return
        }

        // Move desired heading toward a short‑lead prediction now; apply clamp later in decide().
        if let tracker = behavior.tracker {
            behavior.desiredCameraHeading = clampCamera(tracker.predict(leadSeconds: predictionLead))
            behavior.currentContext = .tracking
        } else {
            behavior.desiredCameraHeading = measured
            behavior.currentContext = .tracking
        }
    }

    // MARK: - Parameterization

    private func orientationParameters(for context: OrientationContext)
        -> (headFollowRate: Double, bodyFollowRate: Double)
    {
        switch context {
        case .search:
            if case .patrol(let cfg) = behavior.idleBehavior {
                return (cfg.headFollowRate.clamped(to: 0.05...1.0),
                        cfg.bodyFollowRate.clamped(to: 0.0...1.0))
            }
            return (0.5, 0.15)

        case .tracking, .manual:
            let tr = configuration.trackingBehavior
            return (tr.headFollowRate.clamped(to: 0.05...1.0),
                    tr.bodyFollowRate.clamped(to: 0.0...1.0))
        }
    }

    private func deriveTrackingTuning() {
        let fov = max(20.0, configuration.trackingBehavior.cameraHorizontalFOV)
        deadbandDegrees = configuration.trackingBehavior.deadband
            .clamped(to: 0...0.5) * (fov / 2.0)
        gatingDegrees = max(8.0, min(fov * 0.35, fov / 2.0)) // ~1/3 FOV, bounded
    }

    // MARK: - Initial patrol

    private func configureInitialPatrolState(now: Date) {
        if case .patrol(let cfg) = behavior.idleBehavior, !cfg.headings.isEmpty {
            let index = Int.random(in: 0..<cfg.headings.count)
            let heading = cfg.headings[index]
            behavior.patrol = PatrolState(
                headingIndex: index,
                currentHeading: heading,
                startHeading: heading,
                targetHeading: heading,
                nextSwitch: now + randomInterval(in: cfg.intervalRange),
                transitionStart: now,
                transitionEnd: now
            )
            behavior.bodyTarget = clampBody(heading)
            behavior.headTarget = 0
            behavior.desiredCameraHeading = clampCamera(heading)
            logEvent("patrol.init", values: ["heading": heading, "next": behavior.patrol.nextSwitch.timeIntervalSince1970])
            logState("patrol.target", values: ["heading": heading])
        } else {
            behavior.patrol = PatrolState()
            behavior.bodyTarget = 0
            behavior.headTarget = 0
            behavior.desiredCameraHeading = 0
        }
    }

    // MARK: - Hands

    private func leftHandValue(deltaTime: TimeInterval) -> Double {
        switch behavior.leftGesture {
        case .down:
            return configuration.leftHand.logicalRange.lowerBound
        case .up:
            return configuration.leftHand.logicalRange.upperBound
        case .wave(let amplitude, let speed):
            let safeSpeed = max(speed, 0.2)
            leftWavePhase = (leftWavePhase + deltaTime * safeSpeed * 2 * .pi)
                .truncatingRemainder(dividingBy: 2 * .pi)
            let span = min(amplitude, configuration.leftHand.logicalRange.span)
            let top = configuration.leftHand.logicalRange.upperBound
            let bottom = max(configuration.leftHand.logicalRange.lowerBound, top - span)
            let normalized = (sin(leftWavePhase) + 1) * 0.5
            return bottom + normalized * (top - bottom)
        }
    }

    private func rightHandValue() -> Double {
        let r = configuration.rightHand.logicalRange
        switch behavior.rightGesture {
        case .down:      return r.lowerBound
        case .point:     return r.lowerBound + r.span * 0.5
        case .emphasise: return r.upperBound
        }
    }

    // MARK: - Hardware I/O

    private func applyPose() {
        bodyChannel.move(toLogical: pose.bodyAngle)
        headChannel.move(toLogical: pose.headAngle)
        leftHandChannel.move(toLogical: pose.leftHand)
        rightHandChannel.move(toLogical: pose.rightHand)
    }

    // MARK: - Helpers

    private func clampCamera(_ heading: Double) -> Double { configuration.cameraRange.clamp(heading) }
    private func clampBody(_ angle: Double) -> Double { configuration.body.logicalRange.clamp(angle) }
    private func clampHead(_ angle: Double) -> Double { configuration.head.logicalRange.clamp(angle) }

    /// Shortest signed difference a→b (degrees).
    private func angleDiff(_ a: Double, _ b: Double) -> Double { (b - a) }

    private func syncOnWorkerQueue<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: workerQueueKey) != nil { return work() }
        return workerQueue.sync(execute: work)
    }

    private func telemetryPayload(from values: [String: CustomStringConvertible]) -> [String: Any]? {
        var payload: [String: Any] = ["ts": Date().timeIntervalSince1970]
        for (key, value) in values {
            if let d = value as? Double { payload[key] = d }
            else if let i = value as? Int { payload[key] = i }
            else if let b = value as? Bool { payload[key] = b }
            else { payload[key] = value.description }
        }
        return payload
    }

    private func logEvent(_ type: String, values: [String: CustomStringConvertible] = [:]) {
        var payload: [String: CustomStringConvertible] = ["type": type]
        values.forEach { payload[$0] = $1 }
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

    private func contextName(_ ctx: OrientationContext) -> String {
        switch ctx { case .manual: return "manual"; case .tracking: return "tracking"; case .search: return "search" }
    }

    private func teardownChannelsLocked() {
        leftHandChannel.shutdown()
        rightHandChannel.shutdown()
        headChannel.shutdown()
        bodyChannel.shutdown()
    }
}

// MARK: - ServoChannel (unchanged behavior)

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
        do { try action() }
        catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            throw err
        } catch { print(error); throw error }
    }

    private func perform(_ step: String, _ action: () throws -> Void) {
        do { try action() }
        catch let err as PhidgetError {
            outputError(errorDescription: "[\(configuration.name)] \(step): \(err.description)", errorCode: err.errorCode.rawValue)
            logTelemetry("servo.error", values: ["step": step, "code": err.errorCode.rawValue, "description": err.description])
        } catch { print(error) }
    }

    private func clamp(_ value: Double, min: Double?, max: Double?) -> Double {
        var lower = min, upper = max
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
    func clamp(_ value: Double) -> Double { Swift.min(Swift.max(value, lowerBound), upperBound) }
}
