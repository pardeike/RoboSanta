// StateMachineSettings.swift
// Centralizes the "tweakable" knobs for the figurine controller.

import Foundation

extension StateMachine {
    /// Collection of tunable parameters for Santa's motion, tracking, and gesture behaviour.
    /// Every value is documented with how it affects the figurine and the practical bounds to stay within.
    struct Settings {
        /// Turns diagnostic logging on/off.
        /// Lowering (false) silences console/telemetry noise; raising (true) is useful while tuning.
        /// Typical: true in dev, false for production demos.
        let loggingEnabled: Bool

        /// Normalized horizontal offset (0...1) below which the body is frozen while tracking.
        /// Lower = freeze more often (steadier head, slower body recenter); higher = body keeps moving near center.
        /// Typical: 0.04...0.12.
        let centerHoldOffsetNorm: Double

        /// Maximum camera-space velocity (deg/s) that still qualifies as "steady" for center hold.
        /// Lower = engage hold even on small movements; higher = allow motion before freezing the body.
        /// Typical: 5...20 deg/s.
        let centerHoldVelDeg: Double

        /// Minimum time (s) the face must remain centered/steady before the body hold engages.
        /// Lower = quicker to freeze, more responsive jitter; higher = avoids flip-flopping but reacts slower.
        /// Typical: 0.1...0.4 s.
        let centerHoldMin: TimeInterval

        /// Exponential smoothing factor for face offset (0...1, higher = less smoothing).
        /// Lower = smoother but laggier tracking; higher = snappier but jittery.
        /// Typical: 0.25...0.5.
        let offsetLPFAlpha: Double

        /// Reject tracking updates that jump more than this many degrees in one frame.
        /// Lower = more resistant to detector swaps but may ignore real fast moves; higher = accepts more jumps.
        /// Typical: 10...50 deg.
        let maxJumpDeg: Double

        /// Minimum spacing (deg) between the two patrol extremes after clamping to the camera range.
        /// Lower = allows nearly identical extremes (little motion); higher = collapses near-duplicates.
        /// Typical: 0.0005...0.01 deg.
        let patrolHeadingDedupEpsilon: Double

        /// Maximum time horizon (s) used to lead the target heading.
        /// Lower = trusts measurement, less prediction; higher = more anticipation but risk of overshoot.
        /// Typical: 0...0.15 s.
        let leadSecondsMax: TimeInterval

        /// Cap (deg) on the predictive lead applied to the target.
        /// Lower = safer, less over-steer; higher = can feel snappier but noisier.
        /// Typical: 1...4 deg.
        let leadDegCap: Double

        /// Base blend weight (0...1) for mixing predicted and measured heading; higher = trust prediction more.
        /// Typical: 0.25...0.5.
        let predictionBlendBase: Double

        /// Multiplier applied to the blend weight based on |offset|; higher = ramp trust with offset faster.
        /// Typical: 0.1...0.4.
        let predictionBlendScale: Double

        /// Maximum head slew rate (deg/s).
        /// Lower = smoother head motion; higher = snappier but watch mechanical limits.
        /// Typical: 60...180 deg/s (respect servo limits).
        let headRateCapDegPerSec: Double

        /// Maximum body slew rate (deg/s).
        /// Lower = smoother torso, less counter-sway; higher = quicker re-orient but risk wobble.
        /// Typical: 40...120 deg/s (respect servo limits).
        let bodyRateCapDegPerSec: Double

        /// Minimum heading delta (deg) before re-scheduling orientation updates.
        /// Lower = more frequent reschedules; higher = holds current plan longer.
        /// Typical: 0.2...1.0 deg.
        let orientationRescheduleThreshold: Double

        /// Clamp for the smoothed camera velocity estimate (deg/s) used in prediction.
        /// Lower = reduces aggressive leads; higher = allows faster predictive swings.
        /// Typical: 40...120 deg/s.
        let velCapDegPerSec: Double

        /// Number of wave cycles to perform (full up-down-up movements).
        /// Lower = quick, brief wave; higher = more enthusiastic waving.
        /// Typical: 1...5 cycles.
        let leftHandWaveCycles: Int

        /// Angle (in normalized units) to pull back from max position during each wave.
        /// Lower = subtle wave; higher = more dramatic wave motion.
        /// Typical: 0.05...0.3 (relative to full servo range).
        let leftHandWaveBackAngle: Double

        /// Duration (s) to pause at the top position after waving completes.
        /// Lower = quick return; higher = holds the greeting longer.
        /// Typical: 0.5...2.0 s.
        let leftHandPauseDuration: TimeInterval

        /// Servo velocity (units/s) when raising the hand initially.
        /// Lower = slower, gentler raise; higher = faster greeting.
        /// Typical: 50...300 (depends on servo limits).
        let leftHandRaiseSpeed: Double

        /// Servo velocity (units/s) during the wave motion (both up and down).
        /// Lower = slower, more deliberate wave; higher = quick wave.
        /// Typical: 100...400 (depends on servo limits).
        let leftHandWaveSpeed: Double

        /// Servo velocity (units/s) when lowering the hand at the end.
        /// Lower = gentle return; higher = quick drop.
        /// Typical: 50...200 (depends on servo limits).
        let leftHandLowerSpeed: Double

        /// Maximum time (s) the left hand may stay raised before forcing a cooldown.
        /// Lower = drops the hand sooner to avoid hogging; higher = allows longer hold when someone lingers.
        /// Typical: 3...10 s.
        let leftHandMaxRaisedDuration: TimeInterval

        /// Minimum time-based cooldown (s) between automatic waves once focus is lost.
        /// Lower = more frequent re-greets (risk of spam); higher = fewer waves, more rest.
        /// Typical: 20...60 s.
        let minimumLeftHandCooldown: TimeInterval

        /// Tolerance (in normalized units) for considering servo has reached target position.
        /// Lower = more precise positioning; higher = faster transitions.
        /// Typical: 0.01...0.05.
        let leftHandPositionTolerance: Double

        /// Complete figurine configuration (servos, idle/tracking behaviour, timeouts).
        /// Tweak this when adjusting mechanical ranges, idle patterns, or tracking posture.
        let figurineConfiguration: FigurineConfiguration

        /// Default tuning values used by the app.
        static let `default` = Settings(
            loggingEnabled: true,
            centerHoldOffsetNorm: 0.06,
            centerHoldVelDeg: 10.0,
            centerHoldMin: 0.18,
            offsetLPFAlpha: 0.5,
            maxJumpDeg: 30.0,
            patrolHeadingDedupEpsilon: 0.001,
            leadSecondsMax: 0.08,
            leadDegCap: 2.5,
            predictionBlendBase: 0.35,
            predictionBlendScale: 0.25,
            headRateCapDegPerSec: 250,
            bodyRateCapDegPerSec: 50,
            orientationRescheduleThreshold: 0.5,
            velCapDegPerSec: 80,
            leftHandWaveCycles: 2,
            leftHandWaveBackAngle: 0.15,
            leftHandPauseDuration: 0.75,
            leftHandRaiseSpeed: 200,
            leftHandWaveSpeed: 500,
            leftHandLowerSpeed: 120,
            leftHandMaxRaisedDuration: 6.0,
            minimumLeftHandCooldown: 20.0,
            leftHandPositionTolerance: 0.03,
            figurineConfiguration: .init(
                leftHand: .defaultLeftHand,
                rightHand: .defaultRightHand,
                head: .defaultHead,
                body: .defaultBody,
                idleBehavior: .defaultPatrolBehavior,
                trackingBehavior: .defaultTrackingBehavior,
                leftHandCooldownDuration: StateMachine.FigurineConfiguration.defaultLeftHandCooldownDuration,
                headContributionRatio: StateMachine.FigurineConfiguration.defaultHeadContributionRatio,
                loopInterval: StateMachine.FigurineConfiguration.defaultLoopInterval,
                attachmentTimeout: StateMachine.FigurineConfiguration.defaultAttachmentTimeout
            )
        )

        /// Returns the same settings but with a different figurine configuration.
        func withFigurineConfiguration(_ configuration: FigurineConfiguration) -> Settings {
            Settings(
                loggingEnabled: loggingEnabled,
                centerHoldOffsetNorm: centerHoldOffsetNorm,
                centerHoldVelDeg: centerHoldVelDeg,
                centerHoldMin: centerHoldMin,
                offsetLPFAlpha: offsetLPFAlpha,
                maxJumpDeg: maxJumpDeg,
                patrolHeadingDedupEpsilon: patrolHeadingDedupEpsilon,
                leadSecondsMax: leadSecondsMax,
                leadDegCap: leadDegCap,
                predictionBlendBase: predictionBlendBase,
                predictionBlendScale: predictionBlendScale,
                headRateCapDegPerSec: headRateCapDegPerSec,
                bodyRateCapDegPerSec: bodyRateCapDegPerSec,
                orientationRescheduleThreshold: orientationRescheduleThreshold,
                velCapDegPerSec: velCapDegPerSec,
                leftHandWaveCycles: leftHandWaveCycles,
                leftHandWaveBackAngle: leftHandWaveBackAngle,
                leftHandPauseDuration: leftHandPauseDuration,
                leftHandRaiseSpeed: leftHandRaiseSpeed,
                leftHandWaveSpeed: leftHandWaveSpeed,
                leftHandLowerSpeed: leftHandLowerSpeed,
                leftHandMaxRaisedDuration: leftHandMaxRaisedDuration,
                minimumLeftHandCooldown: minimumLeftHandCooldown,
                leftHandPositionTolerance: leftHandPositionTolerance,
                figurineConfiguration: configuration
            )
        }
    }
}

// MARK: - Pre-set figurine configuration

extension StateMachine.ServoChannelConfiguration {
    /// Left hand servo setup (channel, range, speed).
    /// Adjust pulseRange/logicalRange to match mechanical endpoints; lower velocityLimit for gentler motion.
    /// Typical RC pulse bounds: 500...2500 us; normalized logical range: 0...1.
    static var defaultLeftHand: Self {
        .init(
            name: "LeftHand",
            channel: 0,
            pulseRange: 550...2300,
            logicalRange: 0...1,
            homePosition: 0,
            velocityLimit: 200,
            orientation: .normal,
            voltage: nil,
            stallGuard: nil
        )
    }

    /// Right hand servo setup.
    /// Orientation is reversed so positive values raise the hand; reduce velocityLimit for smoother points.
    /// Typical RC pulse bounds: 500...2500 us; normalized logical range: 0...1.
    static var defaultRightHand: Self {
        .init(
            name: "RightHand",
            channel: 1,
            pulseRange: 550...2300,
            logicalRange: 0...1,
            homePosition: 0,
            velocityLimit: 200,
            orientation: .reversed,
            voltage: nil,
            stallGuard: nil
        )
    }

    /// Head servo setup (pan/tilt of the head relative to the body).
    /// Logical range is in degrees; trim to avoid binding. VelocityLimit tunes snappiness.
    /// Typical yaw range: 20...40 deg either side; pulse bounds 600...2400 us.
    static var defaultHead: Self {
        .init(
            name: "Head",
            channel: 2,
            pulseRange: 700...1200,
            logicalRange: -30...30,
            homePosition: 0,
            velocityLimit: 200,
            orientation: .normal,
            voltage: nil,
            stallGuard: .angularHead
        )
    }

    /// Body servo setup (torso yaw).
    /// Logical range in degrees; narrow if the mount hits stops. VelocityLimit keeps the torso smooth.
    /// Typical yaw range: 60...120 deg total; pulse bounds 700...2300 us.
    static var defaultBody: Self {
        .init(
            name: "Body",
            channel: 3,
            pulseRange: 800...1800,
            logicalRange: -105...105,
            homePosition: 0,
            velocityLimit: 200,
            orientation: .normal,
            voltage: nil,
            stallGuard: .angularBody
        )
    }
}

extension StateMachine.ServoChannelConfiguration.StallGuard {
    /// Default guard tuned for angular servos (head/body) to avoid endless pushing once settled near a limit.
    static var angularHead: Self {
        .init(
            tolerance: 2.0,
            holdDuration: 0.3,
            minMovement: 0.4,
            backoff: 4.0
        )
    }

    /// Body-specific guard with a slightly larger retreat to relieve load when binding at the extremes.
    static var angularBody: Self {
        .init(
            tolerance: 2.0,
            holdDuration: 0.3,
            minMovement: 0.4,
            backoff: 6.0
        )
    }
}

extension StateMachine.FigurineConfiguration.TrackingBehavior {
    /// Baseline tracking behaviour.
    /// - `holdDuration`: Time (s) to keep following after the last detection. Lower = drops target sooner.
    ///   Typical: 2...8 s.
    /// - `headFollowRate`: Fraction (0...1) of error applied to head each tick. Lower = smoother, slower.
    ///   Typical: 0.5...0.9.
    /// - `bodyFollowRate`: Fraction (0...1) of error applied to body. Lower = steadier torso, slower swing.
    ///   Typical: 0.15...0.4.
    /// - `cameraHorizontalFOV`: Horizontal FOV (deg) of the camera. Adjust to match sensor for accurate offsets.
    ///   Typical webcams: 55...85 deg.
    /// - `deadband`: Normalized offset dead zone (0...1) where target holds steady. Lower = more responsive.
    ///   Typical: 0.05...0.12.
    /// - `predictionSmoothing`: 0...1, higher = more filtering of velocity (less prediction). Lower = more lead.
    ///   Typical: 0.15...0.5.
    static var defaultTrackingBehavior: Self {
        .init(
            holdDuration: 6.0,
            headFollowRate: 1.0,
            bodyFollowRate: 1.0,
            cameraHorizontalFOV: 90,
            deadband: 0.08,
            predictionSmoothing: 0.1
        )
    }
}

extension StateMachine.FigurineConfiguration {
    /// Cooldown (s) after losing a person before the left hand may auto-wave again.
    /// Lower = more frequent greetings; higher = conserves motion. Typical: 20...60 s.
    static let defaultLeftHandCooldownDuration: TimeInterval = 20

    /// Fraction (0...1) of idle heading demand assigned to the head vs body.
    /// Lower = body does more, head moves less; higher = head does more, body stays quieter.
    /// Typical: 0.2...0.6.
    static let defaultHeadContributionRatio: Double = 0.4

    /// Loop interval (s) for the control loop.
    /// Lower = tighter control and more CPU load; higher = lighter load but less responsive.
    /// Typical: 0.01...0.05 s.
    static let defaultLoopInterval: TimeInterval = 0.02

    /// Timeout (s) when attaching to a servo channel at startup.
    /// Lower = fail fast on hardware issues; higher = more patience for slow devices.
    /// Typical: 3...8 s.
    static let defaultAttachmentTimeout: TimeInterval = 5
}

extension StateMachine.IdleBehavior.PatrolConfiguration {
    /// Default patrol swing used while idle.
    /// - `headings`: Candidate yaw headings (deg); only the lowest and highest become patrol extremes.
    /// - `intervalRange`: Random pause between movements (s). Lower = more active, higher = calmer.
    /// - `transitionDurationRange`: Random move duration (s). Lower = snappier, higher = smoother sweeps.
    /// - `headFollowRate` / `bodyFollowRate`: Fractions (0...1) of error applied during idle moves.
    /// - `headJitterRange`: Small random jitter (deg) for a lively feel. Set to 0...0 to disable.
    /// - `includeCameraBounds`: When true, adds camera edge headings when establishing the two extremes.
    static var defaultPatrolConfiguration: Self {
        .init(
            headings: [-90, 90],
            intervalRange: 6...10,
            transitionDurationRange: 1.8...3.2,
            headFollowRate: 0.6,
            bodyFollowRate: 0.2,
            headJitterRange: (-5)...5,
            includeCameraBounds: true
        )
    }
}

extension StateMachine.IdleBehavior {
    /// Default idle behaviour: patrols between predefined headings.
    static var defaultPatrolBehavior: StateMachine.IdleBehavior {
        .patrol(.defaultPatrolConfiguration)
    }
}

extension StateMachine.FigurineConfiguration {
    /// Applies `.defaultTrackingBehavior` and `.defaultPatrolBehavior` for convenience.
    static var defaultConfigured: Self {
        StateMachine.Settings.default.figurineConfiguration
    }
}
