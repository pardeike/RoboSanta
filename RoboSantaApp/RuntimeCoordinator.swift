// RuntimeCoordinator.swift
// Coordinates the active rig and detection source.

import Foundation
import Combine

/// Runtime mode for the figurine.
enum SantaRuntime: String {
    case physical
    case virtual
    
    static func fromEnvironment() -> SantaRuntime {
        if let value = ProcessInfo.processInfo.environment["ROBOSANTA_RUNTIME"] {
            return SantaRuntime(rawValue: value.lowercased()) ?? .physical
        }
        if CommandLine.arguments.contains("--virtual") {
            return .virtual
        }
        return .physical
    }
}

/// Coordinates the active rig and detection source.
@MainActor
final class RuntimeCoordinator: ObservableObject {
    @Published private(set) var currentRuntime: SantaRuntime
    @Published private(set) var isRunning = false
    
    private(set) var rig: SantaRig
    private(set) var detectionSource: PersonDetectionSource
    private var router: DetectionRouter?
    private var cancellables = Set<AnyCancellable>()
    
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> {
        rig.poseUpdates
    }
    
    /// Access to the underlying state machine (for backward compatibility)
    var stateMachine: StateMachine {
        rig.stateMachine
    }
    
    init(runtime: SantaRuntime = .fromEnvironment(), settings: StateMachine.Settings = .default) {
        self.currentRuntime = runtime
        
        switch runtime {
        case .physical:
            self.rig = PhysicalRig(settings: settings)
            self.detectionSource = VisionDetectionSource()
        case .virtual:
            self.rig = VirtualRig(settings: settings)
            self.detectionSource = VirtualDetectionSource()
        }
        
        self.router = DetectionRouter(stateMachine: rig.stateMachine)
        router?.connect(to: detectionSource)
    }
    
    func start() async throws {
        try await rig.start()
        detectionSource.start()
        isRunning = true
    }
    
    func stop() async {
        detectionSource.stop()
        await rig.stop()
        isRunning = false
    }
    
    /// Switch runtime (requires restart)
    func switchRuntime(to runtime: SantaRuntime, settings: StateMachine.Settings = .default) async {
        if isRunning {
            await stop()
        }
        
        currentRuntime = runtime
        router?.disconnect()
        
        switch runtime {
        case .physical:
            self.rig = PhysicalRig(settings: settings)
            self.detectionSource = VisionDetectionSource()
        case .virtual:
            self.rig = VirtualRig(settings: settings)
            self.detectionSource = VirtualDetectionSource()
        }
        
        self.router = DetectionRouter(stateMachine: rig.stateMachine)
        router?.connect(to: detectionSource)
    }
    
    /// Send an event directly to the state machine
    func send(_ event: StateMachine.Event) {
        rig.send(event)
    }
}
