// SantaRig.swift
// High-level interface for figurine control.
// Two implementations: PhysicalRig (uses Phidget hardware) and VirtualRig (pure simulation).

import Foundation
import Combine

/// Interval for pose update publishing (20 Hz)
private let poseUpdateInterval: TimeInterval = 0.05

/// High-level interface for figurine control.
/// Two implementations: PhysicalRig (uses Phidget hardware) and VirtualRig (pure simulation).
protocol SantaRig {
    /// Start the rig (connect hardware or begin simulation)
    func start() async throws
    
    /// Stop the rig
    func stop() async
    
    /// Send an event to the state machine
    func send(_ event: StateMachine.Event)
    
    /// Get current pose snapshot
    func poseSnapshot() -> StateMachine.FigurinePose
    
    /// Publisher for pose updates (for SwiftUI binding)
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> { get }
    
    /// The underlying state machine
    var stateMachine: StateMachine { get }
}

/// Physical rig using Phidget hardware.
final class PhysicalRig: SantaRig {
    let stateMachine: StateMachine
    private let poseSubject = PassthroughSubject<StateMachine.FigurinePose, Never>()
    private var poseTimer: Timer?
    
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> {
        poseSubject.eraseToAnyPublisher()
    }
    
    init(settings: StateMachine.Settings = .default) {
        self.stateMachine = StateMachine(
            settings: settings,
            driverFactory: PhidgetServoDriverFactory()
        )
    }
    
    func start() async throws {
        try await stateMachine.start()
        startPosePublisher()
    }
    
    func stop() async {
        poseTimer?.invalidate()
        poseTimer = nil
        await stateMachine.stop()
    }
    
    func send(_ event: StateMachine.Event) {
        stateMachine.send(event)
    }
    
    func poseSnapshot() -> StateMachine.FigurinePose {
        stateMachine.currentPose()
    }
    
    private func startPosePublisher() {
        poseTimer = Timer.scheduledTimer(withTimeInterval: poseUpdateInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.poseSubject.send(self.stateMachine.currentPose())
        }
    }
}

/// Virtual rig using simulated servos.
final class VirtualRig: SantaRig {
    let stateMachine: StateMachine
    private let poseSubject = PassthroughSubject<StateMachine.FigurinePose, Never>()
    private var poseTimer: Timer?
    
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> {
        poseSubject.eraseToAnyPublisher()
    }
    
    init(settings: StateMachine.Settings = .default) {
        self.stateMachine = StateMachine(
            settings: settings,
            driverFactory: VirtualServoDriverFactory()
        )
    }
    
    func start() async throws {
        try await stateMachine.start()
        startPosePublisher()
    }
    
    func stop() async {
        poseTimer?.invalidate()
        poseTimer = nil
        await stateMachine.stop()
    }
    
    func send(_ event: StateMachine.Event) {
        stateMachine.send(event)
    }
    
    func poseSnapshot() -> StateMachine.FigurinePose {
        stateMachine.currentPose()
    }
    
    private func startPosePublisher() {
        poseTimer = Timer.scheduledTimer(withTimeInterval: poseUpdateInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.poseSubject.send(self.stateMachine.currentPose())
        }
    }
}
