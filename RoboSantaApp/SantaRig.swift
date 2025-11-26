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

/// Base implementation of SantaRig that works with any ServoDriverFactory.
/// Use PhysicalRig or VirtualRig convenience subclasses for specific modes.
final class BaseSantaRig: SantaRig {
    let stateMachine: StateMachine
    private let poseSubject = PassthroughSubject<StateMachine.FigurinePose, Never>()
    private var poseTimer: Timer?
    
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> {
        poseSubject.eraseToAnyPublisher()
    }
    
    init(settings: StateMachine.Settings = .default, driverFactory: ServoDriverFactory) {
        self.stateMachine = StateMachine(
            settings: settings,
            driverFactory: driverFactory
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
        // Use an explicit timer + run loop registration so pose updates stay alive in .common modes
        // (e.g. while UI is interacting) instead of relying on the implicit scheduling behavior.
        let timer = Timer(timeInterval: poseUpdateInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.poseSubject.send(self.stateMachine.currentPose())
        }
        poseTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}

/// Physical rig using Phidget hardware.
final class PhysicalRig: SantaRig {
    private let base: BaseSantaRig
    
    var stateMachine: StateMachine { base.stateMachine }
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> { base.poseUpdates }
    
    init(settings: StateMachine.Settings = .default) {
        self.base = BaseSantaRig(settings: settings, driverFactory: PhidgetServoDriverFactory())
    }
    
    func start() async throws { try await base.start() }
    func stop() async { await base.stop() }
    func send(_ event: StateMachine.Event) { base.send(event) }
    func poseSnapshot() -> StateMachine.FigurinePose { base.poseSnapshot() }
}

/// Virtual rig using simulated servos.
final class VirtualRig: SantaRig {
    private let base: BaseSantaRig
    
    var stateMachine: StateMachine { base.stateMachine }
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> { base.poseUpdates }
    
    init(settings: StateMachine.Settings = .default) {
        self.base = BaseSantaRig(settings: settings, driverFactory: VirtualServoDriverFactory())
    }
    
    func start() async throws { try await base.start() }
    func stop() async { await base.stop() }
    func send(_ event: StateMachine.Event) { base.send(event) }
    func poseSnapshot() -> StateMachine.FigurinePose { base.poseSnapshot() }
}
