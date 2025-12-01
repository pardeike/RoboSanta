# VIRTUAL.md - Virtual Santa Implementation Guide

> **⚠️ HISTORICAL DOCUMENT**: This feature has been fully implemented. This document served as the implementation guide and is preserved for reference. See `RuntimeCoordinator.swift`, `SantaRig.swift`, `VirtualServoDriver.swift`, and the `Detection/` folder for the actual implementation.

This document is an **implementation guide** for AI agents to create a virtual santa figurine that mirrors the physical hardware. Read this alongside `AGENTS.md` which provides codebase context.

## Goal

Create a virtual implementation of the RoboSanta figurine that:
- Runs without Phidget hardware or physical camera
- Reuses the existing `StateMachine` logic unchanged
- Allows easy switching between physical and virtual modes
- Enables development and testing without hardware access

## Quick Reference: Key Files to Understand First

Before implementing, study these files in order:

1. **`App.swift`** - Entry point with global `santa` instance (line 9-13)
2. **`Figurine/StateMachine.swift`** - Core logic with private `ServoChannel` class (lines 1276-1461)
3. **`CameraManager.swift`** - Face detection with `driveFigurine()` method (lines 227-242)
4. **`Tools.swift`** - Existing protocols `Think` and `SantaVoice` (lines 4-17)
5. **`Figurine/StateMachineSettings.swift`** - Configuration patterns to follow

## Functional Requirements

### Runtime Switching
- Environment variable `ROBOSANTA_RUNTIME=virtual|physical` (default: `physical`)
- Fallback: command-line flag `--virtual` or `--physical`
- Optional: UI toggle in ContentView for development

### Virtual Rig Requirements
- Mirror all four servos: body, head, leftHand, rightHand
- Produce pose updates via Combine publisher for UI rendering
- Support all `StateMachine.Event` cases identically
- Respect `ServoChannelConfiguration` limits, velocities, and stall guards

### Virtual Person Simulation
- Single virtual person moving laterally across camera field
- Emit `relativeOffset` in range `-1...+1` (matching `CameraManager` output)
- Configurable: path amplitude, speed, dwell time, distance from camera
- Seedable RNG for deterministic test runs

### No Hardware Dependencies
- Virtual mode must not import or reference `Phidget22/` types
- No camera permissions required
- Should compile and run on any macOS 14+ system

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         App.swift                                │
│  (Uses RuntimeCoordinator instead of global santa)              │
└───────────────────────────┬──────────────────────────────────────┘
                            │
              ┌─────────────▼─────────────┐
              │    RuntimeCoordinator     │
              │ (wires rig + detection)   │
              └─────────────┬─────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
    ┌────▼────┐       ┌─────▼─────┐     ┌─────▼──────┐
    │SantaRig │       │Detection  │     │  Preview   │
    │Protocol │       │Source     │     │  Provider  │
    └────┬────┘       │Protocol   │     └────────────┘
         │            └─────┬─────┘
    ┌────┴────┐             │
┌───▼───┐ ┌───▼────┐   ┌────┴────┐ ┌────────┐
│Physical│ │Virtual │   │Vision   │ │Virtual │
│Rig     │ │Rig     │   │Source   │ │Source  │
└────────┘ └────────┘   └─────────┘ └────────┘
    │           │           │           │
    │           │           │           │
[Phidget]  [Virtual    [Camera]   [Simulated
 Servos]    Servos]               Person]
```

## Implementation Details

### Step 1: ServoDriver Protocol

**New file:** `RoboSantaApp/Figurine/ServoDriver.swift`

Extract the servo interface from the private `ServoChannel` class in `StateMachine.swift`:

```swift
/// Protocol for servo hardware abstraction.
/// Physical implementation wraps Phidget RCServo; virtual implementation simulates position over time.
protocol ServoDriver {
    /// Connect to the servo hardware (physical) or initialize simulation (virtual).
    func open(timeout: TimeInterval) throws
    
    /// Disconnect and release resources.
    func shutdown()
    
    /// Command the servo to move to a logical position (e.g., degrees or normalized 0..1).
    func move(toLogical value: Double)
    
    /// Set the velocity limit for subsequent moves.
    func setVelocity(_ velocity: Double)
    
    /// Register a callback for position updates.
    /// For physical servos, invoked when hardware reports position changes.
    /// For virtual servos, invoked at ~50Hz during simulation.
    func setPositionObserver(_ observer: @escaping (Double) -> Void)
    
    /// Register a callback for telemetry logging.
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void)
}

/// Factory that creates four ServoDrivers for the figurine.
protocol ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver
}
```

### Step 2: PhidgetServoDriver

**New file:** `RoboSantaApp/Figurine/PhidgetServoDriver.swift`

Move the existing `ServoChannel` logic from `StateMachine.swift` (lines 1276-1461) into this new class:

```swift
import Foundation

/// Physical servo driver wrapping Phidget RCServo.
/// This is a direct extraction of the existing ServoChannel class.
final class PhidgetServoDriver: ServoDriver {
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
    
    // ... Move all ServoChannel methods here unchanged
}

/// Factory for physical servo drivers.
struct PhidgetServoDriverFactory: ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver {
        PhidgetServoDriver(configuration: config)
    }
}
```

### Step 3: VirtualServoDriver

**New file:** `RoboSantaApp/Figurine/VirtualServoDriver.swift`

```swift
import Foundation

/// Virtual servo driver that simulates position over time.
/// No hardware dependencies; pure Swift simulation.
final class VirtualServoDriver: ServoDriver {
    private let configuration: StateMachine.ServoChannelConfiguration
    private var currentPosition: Double
    private var targetPosition: Double
    private var velocity: Double
    private var positionObserver: ((Double) -> Void)?
    private var telemetryLogger: ((String, [String: CustomStringConvertible]) -> Void)?
    private var simulationTimer: Timer?
    private let simulationInterval: TimeInterval = 0.02  // 50 Hz, matches StateMachine loop
    
    init(configuration: StateMachine.ServoChannelConfiguration) {
        self.configuration = configuration
        self.currentPosition = configuration.homePosition
        self.targetPosition = configuration.homePosition
        self.velocity = configuration.velocityLimit ?? 100
    }
    
    func open(timeout: TimeInterval) throws {
        // Start simulation loop
        simulationTimer = Timer.scheduledTimer(withTimeInterval: simulationInterval, repeats: true) { [weak self] _ in
            self?.updateSimulation()
        }
        if let timer = simulationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        telemetryLogger?("servo.attach", ["channel": configuration.channel])
    }
    
    func shutdown() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        telemetryLogger?("servo.detach", ["channel": configuration.channel])
    }
    
    func move(toLogical value: Double) {
        let clamped = configuration.logicalRange.clamped(value)
        targetPosition = clamped
        telemetryLogger?("servo.command", ["target": clamped])
    }
    
    func setVelocity(_ velocity: Double) {
        self.velocity = velocity
        telemetryLogger?("servo.velocitySet", ["velocity": velocity])
    }
    
    func setPositionObserver(_ observer: @escaping (Double) -> Void) {
        positionObserver = observer
    }
    
    func setTelemetryLogger(_ logger: @escaping (String, [String: CustomStringConvertible]) -> Void) {
        telemetryLogger = logger
    }
    
    private func updateSimulation() {
        // Simulate servo moving toward target at velocity limit
        let maxDelta = velocity * simulationInterval
        let delta = targetPosition - currentPosition
        
        if abs(delta) <= maxDelta {
            currentPosition = targetPosition
        } else {
            currentPosition += (delta > 0 ? maxDelta : -maxDelta)
        }
        
        // Clamp to logical range
        currentPosition = configuration.logicalRange.clamped(currentPosition)
        
        // Notify observer (matches hardware callback pattern)
        positionObserver?(currentPosition)
        telemetryLogger?("servo.position", ["value": currentPosition])
    }
}

/// Factory for virtual servo drivers.
struct VirtualServoDriverFactory: ServoDriverFactory {
    func createDriver(for config: StateMachine.ServoChannelConfiguration) -> ServoDriver {
        VirtualServoDriver(configuration: config)
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
```

### Step 4: Update StateMachine to Use ServoDriverFactory

**Modify:** `RoboSantaApp/Figurine/StateMachine.swift`

Change the initializer to accept a `ServoDriverFactory`:

```swift
// Current (line 239):
init(configuration: FigurineConfiguration = .default, telemetry: TelemetryLogger = .shared, settings: Settings = .default)

// New:
init(
    configuration: FigurineConfiguration = .default, 
    telemetry: TelemetryLogger = .shared, 
    settings: Settings = .default,
    driverFactory: ServoDriverFactory = PhidgetServoDriverFactory()
)
```

Replace the private `ServoChannel` instances with `ServoDriver` protocol references:

```swift
// Current (lines 217-220):
private let leftHandChannel: ServoChannel
private let rightHandChannel: ServoChannel
private let headChannel: ServoChannel
private let bodyChannel: ServoChannel

// New:
private let leftHandDriver: ServoDriver
private let rightHandDriver: ServoDriver
private let headDriver: ServoDriver
private let bodyDriver: ServoDriver
```

**Critical:** Keep the private `ServoChannel` class as `PhidgetServoDriver` in its own file; delete the class from `StateMachine.swift` after extraction.

### Step 5: PersonDetectionSource Protocol

**New file:** `RoboSantaApp/Detection/PersonDetectionSource.swift`

```swift
import Foundation
import CoreGraphics
import Combine

/// Represents a detected face in camera/virtual space.
struct DetectedFace: Equatable {
    /// Normalized bounding box (0...1 in both dimensions)
    let boundingBoxNormalized: CGRect
    /// Face yaw in degrees (nil if not available)
    let yawDeg: Double?
    /// Horizontal offset from center (-1...+1)
    let relativeOffset: Double
}

/// Represents a single frame of detection results.
struct DetectionFrame {
    /// Frame size in pixels
    let size: CGSize
    /// Detected faces in this frame
    let faces: [DetectedFace]
    /// Optional preview image for UI rendering
    let previewImage: CGImage?
}

/// Protocol for person detection sources (camera or virtual).
protocol PersonDetectionSource {
    /// Publisher that emits detection frames
    var detectionFrames: AnyPublisher<DetectionFrame, Never> { get }
    
    /// Start detection
    func start()
    
    /// Stop detection
    func stop()
}
```

### Step 6: DetectionRouter

**New file:** `RoboSantaApp/Detection/DetectionRouter.swift`

Extract the `driveFigurine` logic from `CameraManager.swift` (lines 227-242):

```swift
import Foundation
import Combine

/// Routes detection frames to StateMachine events.
/// Extracted from CameraManager.driveFigurine() for reuse with virtual detection.
final class DetectionRouter {
    private let rig: SantaRig
    private let lostThreshold: TimeInterval
    private var hasActiveFace = false
    private var lastFaceTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init(rig: SantaRig, lostThreshold: TimeInterval = 0.6) {
        self.rig = rig
        self.lostThreshold = lostThreshold
    }
    
    func connect(to source: PersonDetectionSource) {
        source.detectionFrames
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.handleDetectionFrame(frame)
            }
            .store(in: &cancellables)
    }
    
    private func handleDetectionFrame(_ frame: DetectionFrame) {
        let width = frame.size.width
        guard width > 0 else { return }
        
        // Find the face closest to center (matches CameraManager logic)
        if let candidate = frame.faces.min(by: { abs($0.relativeOffset) < abs($1.relativeOffset) }) {
            hasActiveFace = true
            lastFaceTimestamp = Date()
            rig.send(.personDetected(relativeOffset: candidate.relativeOffset))
        } else {
            guard hasActiveFace else { return }
            if let last = lastFaceTimestamp, Date().timeIntervalSince(last) < lostThreshold { return }
            hasActiveFace = false
            lastFaceTimestamp = nil
            rig.send(.personLost)
        }
    }
}
```

### Step 7: VirtualDetectionSource

**New file:** `RoboSantaApp/Detection/VirtualDetectionSource.swift`

```swift
import Foundation
import Combine
import CoreGraphics

/// Configuration for virtual person simulation.
struct VirtualPersonConfig {
    /// Amplitude of lateral oscillation (0...1, where 1 = full camera width)
    var amplitude: Double = 0.8
    /// Period of one full oscillation cycle in seconds
    var period: TimeInterval = 6.0
    /// Time to dwell at each end of the path
    var dwellTime: TimeInterval = 1.0
    /// Distance from camera in meters (affects face size)
    var distance: Double = 1.5
    /// Seed for deterministic simulation (nil = random)
    var seed: UInt64? = nil
    /// Probability of person being "present" (0...1)
    var presenceProbability: Double = 0.8
}

/// Virtual detection source that simulates a person walking past.
final class VirtualDetectionSource: PersonDetectionSource {
    private let config: VirtualPersonConfig
    private let frameSize: CGSize
    private let frameInterval: TimeInterval
    private let detectionSubject = PassthroughSubject<DetectionFrame, Never>()
    private var timer: Timer?
    private var phase: Double = 0
    private var rng: RandomNumberGenerator
    
    var detectionFrames: AnyPublisher<DetectionFrame, Never> {
        detectionSubject.eraseToAnyPublisher()
    }
    
    init(
        config: VirtualPersonConfig = VirtualPersonConfig(),
        frameSize: CGSize = CGSize(width: 1920, height: 1080),
        frameRate: Double = 30
    ) {
        self.config = config
        self.frameSize = frameSize
        self.frameInterval = 1.0 / frameRate
        
        if let seed = config.seed {
            self.rng = SplitMix64(seed: seed)
        } else {
            self.rng = SystemRandomNumberGenerator()
        }
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            self?.generateFrame()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateFrame() {
        // Update phase for oscillation
        phase += frameInterval * (2 * .pi / config.period)
        if phase > 2 * .pi { phase -= 2 * .pi }
        
        // Calculate horizontal offset (-1...+1)
        let offset = sin(phase) * config.amplitude
        
        // Calculate face size based on distance (closer = larger)
        let baseFaceSize = 0.2  // 20% of frame at 1m
        let faceSize = baseFaceSize / config.distance
        
        // Create detection frame
        let faces: [DetectedFace]
        if Double.random(in: 0...1, using: &rng) < config.presenceProbability {
            let boundingBox = CGRect(
                x: (1.0 + offset) / 2.0 - faceSize / 2.0,
                y: 0.5 - faceSize / 2.0,
                width: faceSize,
                height: faceSize
            )
            faces = [DetectedFace(
                boundingBoxNormalized: boundingBox,
                yawDeg: nil,
                relativeOffset: offset
            )]
        } else {
            faces = []
        }
        
        let frame = DetectionFrame(
            size: frameSize,
            faces: faces,
            previewImage: nil  // No preview image for virtual source
        )
        
        detectionSubject.send(frame)
    }
}

/// Simple seedable RNG for deterministic tests.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
```

### Step 8: SantaRig Protocol and Implementations

**New file:** `RoboSantaApp/SantaRig.swift`

```swift
import Foundation
import Combine

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
}

/// Physical rig using Phidget hardware.
final class PhysicalRig: SantaRig {
    private let stateMachine: StateMachine
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
        await stateMachine.stop()
    }
    
    func send(_ event: StateMachine.Event) {
        stateMachine.send(event)
    }
    
    func poseSnapshot() -> StateMachine.FigurinePose {
        stateMachine.currentPose()
    }
    
    private func startPosePublisher() {
        poseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.poseSubject.send(self.stateMachine.currentPose())
        }
    }
}

/// Virtual rig using simulated servos.
final class VirtualRig: SantaRig {
    private let stateMachine: StateMachine
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
        await stateMachine.stop()
    }
    
    func send(_ event: StateMachine.Event) {
        stateMachine.send(event)
    }
    
    func poseSnapshot() -> StateMachine.FigurinePose {
        stateMachine.currentPose()
    }
    
    private func startPosePublisher() {
        poseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.poseSubject.send(self.stateMachine.currentPose())
        }
    }
}
```

### Step 9: RuntimeCoordinator

**New file:** `RoboSantaApp/RuntimeCoordinator.swift`

```swift
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
        
        self.router = DetectionRouter(rig: rig)
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
        
        switch runtime {
        case .physical:
            self.rig = PhysicalRig(settings: settings)
            self.detectionSource = VisionDetectionSource()
        case .virtual:
            self.rig = VirtualRig(settings: settings)
            self.detectionSource = VirtualDetectionSource()
        }
        
        self.router = DetectionRouter(rig: rig)
        router?.connect(to: detectionSource)
    }
}
```

### Step 10: Update App.swift

**Modify:** `RoboSantaApp/App.swift`

```swift
// BEFORE (lines 9-13):
let santa = StateMachine(
    settings: StateMachine.Settings.default.withCameraHorizontalFOV(
        portraitCameraMode ? 60 : 90
    )
)

// AFTER:
// Remove global santa; use coordinator instead
// (coordinator is created in MinimalApp)
```

```swift
// BEFORE (line 17):
struct MinimalApp: App {
    @StateObject private var camera = CameraManager()

// AFTER:
struct MinimalApp: App {
    @StateObject private var coordinator = RuntimeCoordinator(
        settings: StateMachine.Settings.default.withCameraHorizontalFOV(
            portraitCameraMode ? 60 : 90
        )
    )
```

```swift
// BEFORE (App.swift lines 126-128):
static func main() async {
    let loopTask = Task.detached(priority: .background) {
        try await santa.start()
        // await backgroundLoop()
    }
    MinimalApp.main()
    // ... shutdown code
}

// AFTER:
static func main() async {
    // Coordinator handles startup via SwiftUI lifecycle
    // Remove global santa and detached task
    MinimalApp.main()
}
```

## Implementation Order (Refactoring Steps)

Execute these steps in order to minimize risk:

### Phase 1: Extract ServoDriver (No behavior change)
1. Create `ServoDriver.swift` with the protocol
2. Create `PhidgetServoDriver.swift` by copying `ServoChannel` class from `StateMachine.swift`
3. Add `ServoDriverFactory` protocol and `PhidgetServoDriverFactory`
4. Update `StateMachine` init to accept factory (default to Phidget)
5. **Test:** Build and run with hardware - should work identically

### Phase 2: Virtual Servo Implementation
1. Create `VirtualServoDriver.swift`
2. Create `VirtualServoDriverFactory`
3. **Test:** Create simple test that instantiates `StateMachine` with virtual drivers

### Phase 3: Detection Abstraction
1. Create `Detection/` folder
2. Create `PersonDetectionSource.swift` with protocol and models
3. Create `DetectionRouter.swift` extracting logic from `CameraManager.driveFigurine()`
4. Refactor `CameraManager` to implement `PersonDetectionSource` (rename to `VisionDetectionSource`)
5. **Test:** Build and run - camera detection should still work

### Phase 4: Virtual Detection
1. Create `VirtualDetectionSource.swift`
2. **Test:** Create simple test that runs virtual detection with logging

### Phase 5: Rig Abstraction
1. Create `SantaRig.swift` with protocol
2. Create `PhysicalRig` and `VirtualRig` implementations
3. **Test:** Both rigs can be instantiated and started

### Phase 6: Coordinator and Integration
1. Create `RuntimeCoordinator.swift`
2. Update `App.swift` to use coordinator
3. Update `CameraPreview.swift` if needed for virtual frame rendering
4. **Test:** Full app runs in both modes

## Validation Checklist

### Physical Mode Regression
- [ ] App starts and connects to Phidget servos
- [ ] Face detection triggers `.personDetected` events
- [ ] Servos track faces correctly
- [ ] Left hand wave autopilot triggers after focus duration
- [ ] Patrol behavior works when no person detected
- [ ] All telemetry logging still works

### Virtual Mode Verification
- [ ] App starts without hardware connected
- [ ] No camera permission prompts
- [ ] Virtual person generates detection events
- [ ] StateMachine receives offset values sweeping -1 to +1
- [ ] Servo positions update smoothly toward targets
- [ ] Left hand autopilot triggers in virtual mode
- [ ] Pose publisher emits updates for UI

### Determinism Test
- [ ] Run virtual mode with `VirtualPersonConfig(seed: 12345)`
- [ ] Record offset sequence for 10 seconds
- [ ] Run again with same seed
- [ ] Verify identical offset sequence

## Configuration Reference

### Environment Variables
```bash
# Run in virtual mode
ROBOSANTA_RUNTIME=virtual ./RoboSanta.app/Contents/MacOS/RoboSanta

# Run in physical mode (default)
ROBOSANTA_RUNTIME=physical ./RoboSanta.app/Contents/MacOS/RoboSanta
```

### Virtual Person Parameters
Adjust in code when creating `VirtualDetectionSource`:
```swift
VirtualDetectionSource(config: VirtualPersonConfig(
    amplitude: 0.8,      // How far left/right the person walks
    period: 6.0,         // Seconds for one full oscillation
    dwellTime: 1.0,      // Pause at ends
    distance: 1.5,       // Meters from camera
    seed: nil,           // Set for deterministic runs
    presenceProbability: 0.8  // Chance of person being visible
))
```

## Alignment with AGENTS.md

This implementation follows all guidelines from AGENTS.md:

- **Protocol-oriented design:** New protocols (`ServoDriver`, `PersonDetectionSource`, `SantaRig`) follow existing `Think`/`SantaVoice` patterns
- **Do not modify Phidget22/:** All hardware code lives in `PhidgetServoDriver.swift`
- **Preserve StateMachine logic:** Changes limited to dependency injection
- **Honor settings/config:** Virtual parameters use same pattern as `StateMachineSettings.swift`
- **Respect async/await:** All lifecycle methods are async
- **Hardware caution:** Virtual servos still respect ranges and velocity limits

## File Summary

### New Files (9 files)
```
RoboSantaApp/
├── SantaRig.swift                    # SantaRig protocol + PhysicalRig, VirtualRig
├── RuntimeCoordinator.swift          # Wires rig + detection + preview
├── Figurine/
│   ├── ServoDriver.swift             # ServoDriver protocol + factory
│   ├── PhidgetServoDriver.swift      # Extracted from StateMachine.ServoChannel
│   └── VirtualServoDriver.swift      # Pure Swift servo simulation
└── Detection/
    ├── PersonDetectionSource.swift   # Protocol + DetectedFace, DetectionFrame
    ├── DetectionRouter.swift         # Extracted from CameraManager.driveFigurine
    ├── VisionDetectionSource.swift   # Refactored CameraManager
    └── VirtualDetectionSource.swift  # Virtual person simulation
```

### Modified Files (3 files)
```
RoboSantaApp/
├── App.swift                         # Use RuntimeCoordinator instead of global santa
├── Figurine/StateMachine.swift       # Accept ServoDriverFactory in init
└── CameraPreview.swift               # Optional: render virtual frames
```

### Deleted Code
- `StateMachine.swift` private `ServoChannel` class (moved to `PhidgetServoDriver.swift`)
- `CameraManager.swift` `driveFigurine()` method (moved to `DetectionRouter.swift`)

## Simulation Timing Model

The virtual simulation is designed to accurately mirror physical hardware behavior. Understanding the timing model is crucial for debugging and extending the simulation.

### Timing Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Timing Flow Diagram                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PersonGenerator (30 Hz)                                             │
│       │                                                              │
│       ▼                                                              │
│  VirtualDetectionSource ───► DetectionRouter ───► StateMachine       │
│                                                    │                 │
│                                                    │ (50 Hz loop)    │
│                                                    ▼                 │
│                                              updatePose()            │
│                                                    │                 │
│                                                    ▼                 │
│                                              applyPose()             │
│                                                    │                 │
│                                                    ▼                 │
│                                            VirtualServoDriver        │
│                                               (50 Hz)                │
│                                                    │                 │
│                                                    ▼                 │
│                                            positionObserver()        │
│                                                    │                 │
│                                                    ▼                 │
│  RuntimeCoordinator (20 Hz) ◄──── poseUpdates ────┘                  │
│       │                                                              │
│       ▼                                                              │
│  VirtualDetectionSource.cameraHeadingDegrees                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Timing Values

| Component | Rate | Purpose |
|-----------|------|---------|
| PersonGenerator | 30 Hz | Simulates person movement in world space |
| StateMachine loop | 50 Hz | Processes events, updates targets, applies pose |
| VirtualServoDriver | 50 Hz | Simulates servo movement toward targets |
| Pose publisher | 20 Hz | Updates UI and camera heading feedback |

### Velocity Model

The `VirtualServoDriver` interprets velocity values as **normalized velocity** (fraction of logical range per second):

```
Physical velocity value (e.g., 200) 
       │
       ▼ ÷ 200 (scaling factor)
       │
Normalized velocity (1.0 = full range per second)
       │
       ▼ capped to 1.5 max (simulates hardware limits)
       │
       ▼ × logical range span
       │
Target logical velocity (units per second)
       │
       ▼ speed ramping (acceleration/deceleration)
       │
Current velocity (smoothly approaches target)
       │
       ▼ × simulation interval (0.02s)
       │
Position delta per tick (units)
```

**Example calculations (based on default servo configurations):**

> **Note:** These are example ranges from the default servo configurations in `StateMachineSettings.swift`. Actual values may vary based on hardware setup and tuning. The normalized velocity is capped at 1.5 range/sec to simulate physical servo torque limits.

| Servo | Logical Range | Velocity | Normalized | Capped | Logical/sec | Per Tick (0.02s) |
|-------|---------------|----------|------------|--------|-------------|------------------|
| LeftHand | 0...1 (span=1) | 200 | 1.0 | 1.0 | 1.0 units | 0.02 units |
| LeftHand (wave) | 0...1 (span=1) | 500 | 2.5 | 1.5 | 1.5 units | 0.03 units |
| Head | -30...30 (span=60) | 200 | 1.0 | 1.0 | 60 deg | 1.2 deg |
| Body | -105...105 (span=210) | 200 | 1.0 | 1.0 | 210 deg | 4.2 deg |

### Speed Ramping (Acceleration/Deceleration)

Real RC servos with speed ramping enabled (`setSpeedRampingState(true)`) don't instantly reach their target velocity. They accelerate from rest and decelerate when approaching the target position. The `VirtualServoDriver` simulates this behavior:

**Acceleration Phase:**
- When starting a movement, velocity ramps up from 0 toward the target velocity
- Acceleration rate: 8.0 range/sec² (configurable via `accelerationRate`)
- This prevents jerky starts and looks more natural

**Cruising Phase:**
- Once at target velocity, servo moves at constant speed
- This is the majority of longer movements

**Deceleration Phase:**
- When within 25% of the logical range from target, velocity starts decreasing
- Uses a sqrt curve for smooth, natural-feeling slowdown
- Minimum velocity of 0.15 range/sec prevents stalling near target

**Direction Changes:**
- When target changes direction, velocity resets to 0
- This simulates real servo motor behavior where the motor must stop before reversing

This ramping behavior is especially noticeable during wave motions, where the back-and-forth movement has visible acceleration and deceleration at each reversal point.

### Camera Heading Feedback Loop

For accurate simulation, the virtual detection source must use the **measured** camera heading (actual servo positions) rather than the **target** heading (commanded positions). This ensures the feedback loop correctly accounts for servo lag:

```swift
// In RuntimeCoordinator.setupCameraHeadingUpdates()
virtualSource.cameraHeadingDegrees = self.rig.stateMachine.cameraHeading()
// NOT: pose.cameraHeading (which uses target positions)
```

This is important because:
1. `pose.cameraHeading` = `bodyAngle + headAngle` (target positions)
2. `stateMachine.cameraHeading()` = measured positions when available
3. Virtual servos take time to reach targets, so there's lag between target and actual

### Debugging Tips

1. **Servo moving too fast or instant**: Check velocity scaling factor and logical range span multiplication
2. **Camera not tracking correctly**: Verify `cameraHeadingDegrees` is updated with measured values
3. **Jerky motion**: Check timer scheduling and run loop modes
4. **Person detection flicker**: Adjust `lostThreshold` in `DetectionRouter` (default 0.6s)
