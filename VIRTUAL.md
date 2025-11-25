# VIRTUAL.md - Virtual Santa Plan

## Goal
- Let developers run RoboSanta without hardware by swapping between two interchangeable runtimes: the current physical figurine and a fully virtual rig (4 servos + synthetic camera feed).
- Keep the AI/TTS loop untouched; only the sensor/actuator layer changes.
- Reuse the existing state machine logic so behaviour stays identical between physical and virtual runs.

## Functional requirements
- Runtime switch to choose `physical` or `virtual` (env var, CLI flag, or UI toggle). Default to `physical` to preserve current behaviour.
- Shared high-level interface for figurine control (start/stop, event input, pose readback, telemetry) with two implementations.
- Virtual rig mirrors four servos (body, head, leftHand, rightHand) and produces pose/telemetry just like the physical one.
- Person simulation: a single virtual person walks laterally (orthogonal to Santa’s forward axis) across the camera field, oscillating left/right in front of the figurine; face detection should emit offsets in the same range the real camera uses (-1...+1 from center).
- Fake video feed that the face detection pipeline can consume and that the camera preview can show (bounding boxes + optional rendered frame).
- Shared face-detection interface so the state machine receives identical `.personDetected` / `.personLost` events from either the real camera or the virtual generator.
- Deterministic option (seeded) for repeatable tests; tunable parameters for path amplitude, speed, dwell, and depth.
- No hardware or camera permissions needed for the virtual runtime.

## Architecture / abstractions

### Santa runtime + rig interface
- Introduce `SantaRuntime` enum (`physical`, `virtual`) and a factory that produces the active rig based on config.
- Define a `SantaRig` protocol (lives in `RoboSantaApp/` root):
  - `func start() async throws`, `func stop() async`
  - `func send(_ event: StateMachine.Event)`
  - `func poseSnapshot() -> FigurinePose` (mirrors `StateMachine.FigurinePose`)
  - `var poseUpdates: AnyPublisher<FigurinePose, Never>` (for SwiftUI/preview rendering)
  - Optional telemetry hooks for logging.
- Physical rig: thin wrapper around existing `StateMachine` + Phidget servos.
- Virtual rig: uses the same `StateMachine` but with virtual servo drivers (no Phidget dependency) and publishes simulated pose.

### Servo abstraction
- Extract hardware-specific logic from `StateMachine.ServoChannel` into a new `ServoDriver` protocol:
  - `open(timeout:)`, `shutdown()`, `move(toLogical:)`, `setVelocity(_:)`, `setPositionObserver(_:)`.
  - Keep `ServoChannelConfiguration` as the shared description of ranges, orientation, home position, stall guard, etc.
- Implementations:
  - `PhidgetServoDriver`: wraps the current RCServo code (mostly moving existing `ServoChannel` logic out of `StateMachine.swift`).
  - `VirtualServoDriver`: pure Swift object that simulates position over time (track current position, velocity limit, optional stall guard/backoff behaviour) and invokes observers to mimic hardware callbacks.
- Update `StateMachine` to accept a `ServoDriverFactory` (or injected drivers) so it no longer hardcodes RCServo construction. Preserve the rest of the control logic unchanged.

### Detection abstraction
- Define a `PersonDetectionSource` protocol (separate from rig):
  - Lifecycle: `start()`, `stop()`.
  - Output: publisher/closure emitting `DetectionFrame` structs containing:
    - `size: CGSize` (frame size of the feed)
    - `[DetectedFace]` where `DetectedFace` holds `boundingBoxNormalized: CGRect`, `yawDeg: Double?`, `relativeOffset: Double`
    - Optional raw pixel buffer/CGImage for preview use.
- Add a small router that turns `DetectionFrame` updates into `StateMachine` events (repurposes `driveFigurine` logic currently inside `CameraManager`), so the state machine no longer depends on Vision directly.
- Real source: refactor `CameraManager` to become `VisionDetectionSource` implementing the protocol. Keep session/preview wiring, but emit detection frames through the shared interface and let the router send `.personDetected`/`.personLost`.
- Virtual source: `VirtualDetectionSource` that produces synthetic frames + detections (see model below). Should not depend on AVFoundation; generate simple `CGImage` or `CIImage` placeholders for preview overlays.

### Composition
- Introduce a lightweight `RuntimeCoordinator` (new file, referenced from `App.swift`) that wires:
  - active `SantaRig`
  - active `PersonDetectionSource`
  - router connecting detections to rig events
  - preview provider for SwiftUI
- `App.swift` stops using the global `santa`; it asks the coordinator for the active rig and passes a pose publisher into SwiftUI if needed.

## Virtual world model
- Figurine: 30 cm tall, camera at ~head height; assume HD sensor, horizontal FOV default 90° (already configurable).
- Person: represented by a simple state machine:
  - Position `(x, z)` where `x` oscillates across the camera plane (sin wave or ping-pong), `z` is forward distance (configurable, e.g., 0.8–2.0 m).
  - Speed and pause controls to mimic someone walking past, stopping briefly, then leaving.
  - Face size derived from `z` to set bounding box height/width; keep boxes inside 0...1 normalized viewport.
- Detection synthesis:
  - Project `(x, z)` into normalized screen coords using FOV; horizontal offset becomes `relativeOffset` for `StateMachine`.
  - Generate `DetectedFace.boundingBoxNormalized` centered at that screen position with size scaled by `z`.
  - Emit `.personLost` after configurable timeout with no faces.
- Servo simulation:
  - Each virtual servo tracks toward the commanded normalized target using velocity limits from configuration; publishes `position` periodically so stall guard and left-hand autopilot logic still run.

## Refactoring steps (ordered)
1) Create `SantaRuntime` config + `SantaRig` protocol and `RuntimeCoordinator` scaffold (no behaviour change). Update `App.swift` to use the coordinator instead of the global `santa`.
2) Extract the existing RCServo logic from `StateMachine.swift` into `PhidgetServoDriver` (new file), leaving `StateMachine` to depend on a `ServoDriverFactory` that yields four drivers.
3) Implement `VirtualServoDriver` and a `VirtualRig` that instantiates `StateMachine` with virtual drivers and publishes pose updates.
4) Define shared detection models (`DetectionFrame`, `DetectedFace`) and `PersonDetectionSource` protocol. Move the face-to-event logic out of `CameraManager` into a reusable router.
5) Refactor `CameraManager` into `VisionDetectionSource` + a thin preview host. The router feeds events to the active rig.
6) Build `VirtualDetectionSource` + `VirtualPerson` simulation (configurable path/speed). Add seedable RNG for deterministic runs.
7) Update `CameraPreview` to render either real video (`AVCaptureVideoPreviewLayer`) or virtual frames (e.g., `NSImage` layer) and always draw detection overlays from `DetectionFrame`.
8) Add configuration knobs (env vars or UI) for runtime selection, virtual person parameters, and camera FOV used by the virtual feed.
9) Document how to run in virtual mode (no hardware required) and how to switch back to physical.

## Preview and future UI hooks
- Expose the virtual pose stream so SwiftUI can render a virtual Santa view (later step).
- Ensure `DetectionFrame` overlays drive both the real preview and the synthetic feed uniformly.
- Keep an option to mirror the virtual feed to match camera mirroring so left/right offsets remain consistent.

## Validation plan
- Virtual runtime: verify the state machine receives `.personDetected` offsets sweeping from -1 to +1 as the person crosses; check pose updates follow tracking logic and left-hand autopilot still triggers.
- Physical runtime regression: confirm Phidget wiring untouched aside from the new abstraction layer; build/run with hardware attached.
- Determinism: run virtual mode with a fixed seed and confirm identical offset sequences over time.

## Alignment with AGENTS.md
- Keep protocol-oriented design: new `SantaRig`, `ServoDriver`, and detection source protocols follow existing `Think`/`SantaVoice` patterns.
- Do **not** modify `Phidget22/`; all hardware code lives in a new `PhidgetServoDriver`.
- Preserve `StateMachine` logic; changes are limited to dependency injection of servo drivers, not behavioural rewrites.
- Honor settings/config structs; avoid hardcoding values (virtual parameters should be configurable and/or seeded).
- Respect async/await patterns for lifecycle and detection; avoid completion handlers.
- Swedish prompts remain unchanged; virtual mode only replaces hardware and camera inputs.
- Note the hardware caution: servo abstractions must still respect ranges, stall guards, and logging toggles to avoid unsafe physical motions when running the physical rig.

## Files to touch when implementing
- `App.swift` (remove global santa; use coordinator)
- `RoboSantaApp/Figurine/StateMachine.swift` (inject servo drivers; no logic changes otherwise)
- New: `ServoDriver.swift`, `PhidgetServoDriver.swift`, `VirtualServoDriver.swift`, `SantaRig.swift`, `RuntimeCoordinator.swift`
- `RoboSantaApp/CameraManager.swift` (refactor into detection source), `CameraPreview.swift` (render abstraction)
- New: `DetectionModels.swift`, `PersonDetectionSource.swift`, `VirtualDetectionSource.swift`
