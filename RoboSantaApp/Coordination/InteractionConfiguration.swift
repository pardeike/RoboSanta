// InteractionConfiguration.swift
// Configuration for the interaction coordinator.

import Foundation

/// Configuration for the InteractionCoordinator.
/// Defines thresholds and timing for person engagement detection.
struct InteractionConfiguration: Equatable, Sendable {
    /// Maximum face yaw angle (degrees) for considering person "engaged"
    /// Person is looking at Santa if abs(yaw) <= this value
    let faceYawToleranceDeg: Double
    
    /// More lenient yaw tolerance used after greeting to decide whether to continue
    /// with the conversation. Allows attention capture from wider angles.
    let postGreetingFaceYawToleranceDeg: Double
    
    /// Minimum tracking duration (seconds) before starting interaction
    /// Prevents triggering on people just walking past
    let personDetectionDurationSeconds: TimeInterval
    
    /// Duration (seconds) after person lost before skipping farewell
    /// If person is gone longer than this, don't play farewell
    let farewellSkipThresholdSeconds: TimeInterval
    
    /// Maximum duration to wait for person to look back during conversation
    /// If person doesn't look back within this time, skip to farewell
    let lookAwayTimeoutSeconds: TimeInterval
    
    /// Delay between checking engagement during conversation
    let engagementCheckIntervalSeconds: TimeInterval
    
    /// Default configuration with sensible values
    static let `default` = InteractionConfiguration(
        faceYawToleranceDeg: 5.0,
        postGreetingFaceYawToleranceDeg: 35.0,
        personDetectionDurationSeconds: 1.0,
        farewellSkipThresholdSeconds: 3.0,
        lookAwayTimeoutSeconds: 2.0,
        engagementCheckIntervalSeconds: 0.5
    )
    
    /// Creates a configuration with custom values.
    init(
        faceYawToleranceDeg: Double = 5.0,
        postGreetingFaceYawToleranceDeg: Double = 35.0,
        personDetectionDurationSeconds: TimeInterval = 1.0,
        farewellSkipThresholdSeconds: TimeInterval = 3.0,
        lookAwayTimeoutSeconds: TimeInterval = 2.0,
        engagementCheckIntervalSeconds: TimeInterval = 0.5
    ) {
        self.faceYawToleranceDeg = faceYawToleranceDeg
        self.postGreetingFaceYawToleranceDeg = postGreetingFaceYawToleranceDeg
        self.personDetectionDurationSeconds = personDetectionDurationSeconds
        self.farewellSkipThresholdSeconds = farewellSkipThresholdSeconds
        self.lookAwayTimeoutSeconds = lookAwayTimeoutSeconds
        self.engagementCheckIntervalSeconds = engagementCheckIntervalSeconds
    }
}
