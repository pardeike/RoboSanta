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
    private var cameraHeadingCancellable: AnyCancellable?
    
    var poseUpdates: AnyPublisher<StateMachine.FigurinePose, Never> {
        rig.poseUpdates
    }
    
    /// Access to the underlying state machine (for backward compatibility)
    var stateMachine: StateMachine {
        rig.stateMachine
    }
    
    convenience init() {
        self.init(runtime: .fromEnvironment(), settings: .default)
    }
    
    convenience init(settings: StateMachine.Settings) {
        self.init(runtime: .fromEnvironment(), settings: settings)
    }
    
    /// Initialize with a specific runtime mode and settings.
    /// - Parameters:
    ///   - runtime: The runtime mode (physical or virtual).
    ///   - settings: State machine settings.
    ///   - personGenerator: Optional custom person generator for virtual mode.
    ///                      If nil, uses the default OscillatingPersonGenerator.
    init(runtime: SantaRuntime, settings: StateMachine.Settings, personGenerator: (any PersonGenerator)? = nil) {
        self.currentRuntime = runtime
        
        switch runtime {
        case .physical:
            self.rig = PhysicalRig(settings: settings)
            self.detectionSource = VisionDetectionSource()
        case .virtual:
            self.rig = VirtualRig(settings: settings)
            let generator = personGenerator ?? OscillatingPersonGenerator()
            let detectionConfig = VirtualDetectionConfig(
                cameraHorizontalFOV: settings.figurineConfiguration.trackingBehavior.cameraHorizontalFOV
            )
            self.detectionSource = VirtualDetectionSource(generator: generator, config: detectionConfig)
        }
        
        self.router = DetectionRouter(stateMachine: rig.stateMachine)
        router?.connect(to: detectionSource)
        setupCameraHeadingUpdates()
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
    func switchRuntime(to runtime: SantaRuntime) async {
        await switchRuntime(to: runtime, settings: .default, personGenerator: nil)
    }
    
    /// Switch runtime with custom settings.
    func switchRuntime(to runtime: SantaRuntime, settings: StateMachine.Settings) async {
        await switchRuntime(to: runtime, settings: settings, personGenerator: nil)
    }
    
    /// Switch runtime with custom settings and person generator.
    /// - Parameters:
    ///   - runtime: The runtime mode to switch to.
    ///   - settings: State machine settings.
    ///   - personGenerator: Optional custom person generator for virtual mode.
    func switchRuntime(to runtime: SantaRuntime, settings: StateMachine.Settings, personGenerator: (any PersonGenerator)?) async {
        if isRunning {
            await stop()
        }
        
        currentRuntime = runtime
        router?.disconnect()
        cameraHeadingCancellable?.cancel()
        cameraHeadingCancellable = nil
        
        switch runtime {
        case .physical:
            self.rig = PhysicalRig(settings: settings)
            self.detectionSource = VisionDetectionSource()
        case .virtual:
            self.rig = VirtualRig(settings: settings)
            let generator = personGenerator ?? OscillatingPersonGenerator()
            let detectionConfig = VirtualDetectionConfig(
                cameraHorizontalFOV: settings.figurineConfiguration.trackingBehavior.cameraHorizontalFOV
            )
            self.detectionSource = VirtualDetectionSource(generator: generator, config: detectionConfig)
        }
        
        self.router = DetectionRouter(stateMachine: rig.stateMachine)
        router?.connect(to: detectionSource)
        setupCameraHeadingUpdates()
    }
    
    /// Send an event directly to the state machine
    func send(_ event: StateMachine.Event) {
        rig.send(event)
    }
    
    // MARK: - Private
    
    /// Connect pose updates to the virtual detection source so it knows the camera heading.
    /// This allows the virtual detection source to calculate where a person would appear
    /// in the camera frame based on the camera's actual orientation.
    private func setupCameraHeadingUpdates() {
        guard let virtualSource = detectionSource as? VirtualDetectionSource else { return }
        
        cameraHeadingCancellable = rig.poseUpdates
            .receive(on: DispatchQueue.main)
            .sink { pose in
                // Update the camera heading in the virtual detection source
                // Camera heading = body angle + head angle
                virtualSource.cameraHeadingDegrees = pose.cameraHeading
            }
    }
}
