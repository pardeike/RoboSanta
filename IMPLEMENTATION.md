# RoboSanta Interactive Speech System - Implementation Design

## Overview

This document describes the architecture for integrating **SantaSpeaker** (speech generation) with **StateMachine** (animatronics control) to create a fully coordinated interactive Santa experience. The system will generate conversation sets in the background, queue them on the filesystem, and intelligently play them when people approach and engage with Santa.

---

## System Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SantaSpeaker (Background)                     │
│  Continuously generates conversation sets → filesystem queue     │
│  Folder: SpeechQueue/YYYYMMDDHHMMSS/{start,middle*,end}.wav    │
└─────────────────────────────────────────────────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │  Filesystem Queue     │
                    │  (sorted by timestamp)│
                    └───────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│              InteractionCoordinator (New Component)              │
│  • Monitors queue and person detection                          │
│  • Coordinates StateMachine and audio playback                  │
│  • Tracks interaction state (idle/patrolling/greeting/speaking) │
│  • Monitors face angle to decide engagement                     │
└─────────────────────────────────────────────────────────────────┘
                    ↓                           ↓
        ┌───────────────────┐       ┌──────────────────────┐
        │   StateMachine    │       │   AudioPlayer        │
        │  (animations)     │       │   (TTS playback)     │
        └───────────────────┘       └──────────────────────┘
```

### Component Responsibilities

#### 1. **SantaSpeaker** (Enhanced)
- **Current**: Generates speech independently in a loop
- **New Behavior**:
  - Generates conversation sets as timestamped folders
  - Each set contains: `start.wav`, `middle1.wav`, `middle2.wav`, ..., `end.wav`
  - Stores in configurable `SpeechQueue/` directory
  - Generation rate configurable (default: continuous with throttling)
  - No longer directly triggers TTS playback

#### 2. **InteractionCoordinator** (New)
- **Core orchestration layer** between SantaSpeaker and StateMachine
- Monitors filesystem queue for available conversation sets
- Subscribes to person detection events from StateMachine
- Tracks face yaw angle to determine engagement worthiness
- Manages interaction state machine (see below)
- Commands StateMachine idle behavior based on queue state
- Triggers audio playback with proper timing
- Moves consumed sets to `SpeechQueue/DONE/` folder

#### 3. **StateMachine** (Minimal Changes)
- **New**: Expose face yaw angle in person detection events
- **New**: Add `InteractionState` tracking for coordination
- **Enhanced**: Support new idle animation mode (minimal movement)
- **Existing**: All person tracking, servo control, gesture automation

#### 4. **AudioPlayer** (New or Enhanced)
- Plays WAV files sequentially with state tracking
- Reports playback status (playing/completed)
- Supports interruption for person loss scenarios

---

## Filesystem Queue Structure

### Directory Layout

```
SpeechQueue/
├── 20250327143022/          # Timestamp: YYYY-MM-DD HH:MM:SS
│   ├── start.wav
│   ├── middle1.wav
│   ├── middle2.wav
│   └── end.wav
├── 20250327143517/
│   ├── start.wav
│   ├── middle1.wav
│   └── end.wav
└── DONE/                    # Consumed sets moved here
    ├── 20250327143022/
    └── 20250327142901/
```

### Set Structure Rules

1. **Folder naming**: `YYYYMMDDHHMMSS` (14 digits, sortable)
2. **Required files**: `start.wav`, `end.wav`
3. **Optional files**: `middle1.wav`, `middle2.wav`, ..., `middleN.wav` (numbered sequentially)
4. **Validation**: InteractionCoordinator validates sets before use
5. **Consumption**: Atomic move to DONE/ folder after use (or on person loss)

### Configuration

```swift
struct SpeechQueueConfiguration {
    let queueDirectory: URL             // Default: ~/RoboSanta/SpeechQueue
    let doneDirectory: URL              // Default: ~/RoboSanta/SpeechQueue/DONE
    let maxQueueSize: Int               // Max sets before pausing generation (default: 20)
    let minQueueSize: Int               // Min sets before resuming generation (default: 5)
    let generationThrottleSeconds: Int  // Delay between generations (default: 180)
}
```

---

## Interaction State Machine

### States

The **InteractionCoordinator** manages these states:

```swift
enum InteractionState {
    case idle                    // Queue empty, minimal idle animation
    case patrolling             // Queue has content, looking for people
    case personDetected         // Person found, evaluating engagement
    case greeting               // Playing start.wav, monitoring face angle
    case conversing             // Playing middle*.wav phrases
    case farewell               // Playing end.wav
    case personLost             // Person left, cleanup in progress
}
```

### State Transitions

```
┌──────┐  queue empty   ┌────────────┐
│ idle │◄───────────────│ patrolling │
└──┬───┘                └─────┬──────┘
   │                          │
   │ queue has content        │ person detected
   │                          ↓
   └──────────────►  ┌──────────────────┐
                     │ personDetected   │
                     └────────┬─────────┘
                              │
                     face angle OK (±5°)
                              ↓
                     ┌─────────────┐
                     │  greeting   │────┐ person lost anytime
                     └──────┬──────┘    ↓
                            │      ┌────────────┐
                    start.wav done│ personLost │
                            ↓      └─────┬──────┘
                     ┌────────────┐      │
                     │ conversing │◄─────┘ (move set to DONE,
                     └──────┬─────┘         resume patrol/idle)
                            │
               all middle*.wav done OR person not looking
                            ↓
                     ┌───────────┐
                     │ farewell  │
                     └─────┬─────┘
                           │
                      end.wav done
                           ↓
                     (move set to DONE,
                      resume patrol/idle)
```

### Decision Points

1. **Person Detection → Greeting**:
   - Queue has at least 1 set
   - Person tracked for > 1.0 seconds
   - Face yaw angle within ±5° (person looking at Santa)
   - StateMachine not in cooldown

2. **Greeting → Conversing**:
   - `start.wav` finished playing
   - Person still detected AND still looking (yaw ±5°)
   - Middle phrases exist

3. **Conversing → Next Middle or Farewell**:
   - Always finish current phrase completely
   - After phrase: check if person still looking
   - If looking AND more middle phrases: play next
   - If not looking OR no more phrases: go to farewell

4. **Farewell Decision**:
   - Skip farewell if person fully lost (detection timeout > 3s)
   - Play farewell if person recently lost but still in holdDuration window

---

## Coordination Mechanisms

### Problem: Two State Machines Need to Know About Each Other

Both SantaSpeaker and StateMachine need coordination without tight coupling.

### Solution: Shared State via InteractionCoordinator

```swift
@Observable
class InteractionCoordinator {
    // Shared state
    private(set) var state: InteractionState = .idle
    private(set) var isSpeaking: Bool = false
    private(set) var queueCount: Int = 0

    // Detection state from StateMachine
    private var personTracked: Bool = false
    private var faceYawAngle: Double? = nil
    private var lastDetectionTime: Date? = nil

    // Current conversation
    private var currentSet: ConversationSet? = nil
    private var currentPhaseIndex: Int = 0

    // Dependencies (injected)
    private let stateMachine: StateMachine
    private let audioPlayer: AudioPlayer
    private let queueManager: SpeechQueueManager
}
```

### Communication Patterns

#### StateMachine → InteractionCoordinator

```swift
// StateMachine publishes detection events
extension StateMachine {
    struct DetectionUpdate {
        let personDetected: Bool
        let relativeOffset: Double
        let faceYaw: Double?        // NEW: from VisionDetectionSource
        let timestamp: Date
    }

    // Publisher for coordinator to subscribe
    var detectionPublisher: AnyPublisher<DetectionUpdate, Never>
}

// InteractionCoordinator subscribes
detectionPublisher
    .sink { [weak self] update in
        self?.handleDetectionUpdate(update)
    }
    .store(in: &cancellables)
```

#### InteractionCoordinator → StateMachine

```swift
// Coordinator commands StateMachine
func updateIdleBehavior(queueHasContent: Bool) {
    if queueHasContent {
        stateMachine.send(.setIdleBehavior(.patrol(.defaultPatrolConfiguration)))
    } else {
        stateMachine.send(.setIdleBehavior(.minimalIdle))  // NEW mode
    }
}

// Coordinate gestures with speech
func synchronizeGesture(for phrase: PhraseType) {
    switch phrase {
    case .greeting:
        // Left hand auto-wave already handles this
        break
    case .middle(let emphasis):
        if emphasis {
            stateMachine.send(.setRightHand(.emphasise))
            // Return to .down after 0.5s
        }
    case .farewell:
        // Let existing wave complete naturally
        break
    }
}
```

### Thread Safety

- **StateMachine**: Already uses dedicated `workerQueue`
- **InteractionCoordinator**: Uses `@MainActor` for state updates
- **Communication**: Combine publishers handle thread transitions
- **File Operations**: Background queue for queue management

---

## New Components Detail

### 1. ConversationSet

```swift
struct ConversationSet: Identifiable {
    let id: String              // Folder name (timestamp)
    let folderURL: URL
    let startFile: URL
    let middleFiles: [URL]      // Sorted middle1, middle2, ...
    let endFile: URL
    let createdAt: Date

    var totalPhrases: Int { 1 + middleFiles.count + 1 }

    init?(folderURL: URL) {
        // Validates structure and returns nil if invalid
    }
}
```

### 2. SpeechQueueManager

```swift
@Observable
class SpeechQueueManager {
    private let config: SpeechQueueConfiguration
    private(set) var availableSets: [ConversationSet] = []

    func scanQueue() -> [ConversationSet]
    func consumeOldest() -> ConversationSet?
    func moveToCompleted(_ set: ConversationSet)
    func getQueueCount() -> Int
    func pruneCompletedSets(keepingLast: Int)  // Cleanup old DONE sets
}
```

### 3. AudioPlayer

```swift
@Observable
class AudioPlayer {
    enum PlaybackState {
        case idle
        case playing(URL)
        case completed
        case interrupted
    }

    private(set) var state: PlaybackState = .idle

    func play(_ fileURL: URL) async
    func stop()
    func waitForCompletion() async -> Bool  // Returns false if interrupted
}
```

### 4. Enhanced SantaSpeaker

```swift
struct SantaSpeaker {
    let queueConfig: SpeechQueueConfiguration
    let queueManager: SpeechQueueManager

    func start() {
        Task { await runGenerationLoop() }
    }

    private func runGenerationLoop() async {
        while !Task.isCancelled {
            // Check queue size
            if queueManager.getQueueCount() >= queueConfig.maxQueueSize {
                try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5s
                continue
            }

            // Generate a conversation set
            let set = await generateConversationSet()

            // Save to filesystem
            await saveSet(set, to: queueManager)

            // Throttle
            try? await Task.sleep(nanoseconds: UInt64(queueConfig.generationThrottleSeconds) * 1_000_000_000)
        }
    }

    private func generateConversationSet() async -> ConversationSet {
        let timestamp = formatTimestamp(Date())
        let setFolder = queueConfig.queueDirectory.appendingPathComponent(timestamp)

        // Create folder
        try? FileManager.default.createDirectory(at: setFolder, withIntermediateDirectories: true)

        // Generate content (same as current, but structured)
        let interactionType = Int.random(in: 0...3)

        switch interactionType {
        case 1: // Greeting (start + conversation + goodbye)
            let r: GreetOut = try await thinker.generate(...)
            await voice.tts(setFolder.appendingPathComponent("start.wav").path, r.helloPhrase)
            await voice.tts(setFolder.appendingPathComponent("middle1.wav").path, r.conversationPhrase)
            await voice.tts(setFolder.appendingPathComponent("end.wav").path, r.goodbyePhrase)

        case 2: // Quiz
            // Similar structure

        // ... other types
        }

        return ConversationSet(folderURL: setFolder)!
    }
}
```

---

## Minimal Idle Animation

When the queue is empty, Santa should do a subtle idle animation instead of full patrol.

### New IdleBehavior Case

```swift
extension StateMachine.IdleBehavior {
    case minimalIdle(MinimalIdleConfiguration)

    struct MinimalIdleConfiguration: Equatable {
        let centerHeading: Double           // Default: 0
        let headSwayAmplitude: Double       // Default: 3 degrees
        let headSwayPeriod: TimeInterval    // Default: 8 seconds
        let bodyStillness: Bool             // Default: true (body doesn't move)
    }
}
```

### Implementation

```swift
// In StateMachine.idleHeading()
case .minimalIdle(let config):
    let span = max(config.headSwayPeriod, 0.1)
    idlePhase = (idlePhase + deltaTime * (2 * .pi / span)).truncatingRemainder(dividingBy: 2 * .pi)
    let headSway = sin(idlePhase) * config.headSwayAmplitude

    // Only head moves slightly, body stays at center
    behavior.bodyTarget = config.centerHeading
    behavior.headTarget = headSway

    return config.centerHeading + headSway
```

---

## Face Angle Integration

Currently, `VisionDetectionSource` detects face yaw but StateMachine doesn't use it.

### Changes Required

#### In DetectionRouter

```swift
// Current
stateMachine.send(.personDetected(relativeOffset: closestFace.relativeOffset))

// New
stateMachine.send(.personDetected(
    relativeOffset: closestFace.relativeOffset,
    faceYaw: closestFace.yawDeg  // NEW parameter
))
```

#### In StateMachine.Event

```swift
enum Event: Equatable {
    // Current
    case personDetected(relativeOffset: Double)

    // New
    case personDetected(relativeOffset: Double, faceYaw: Double?)

    // ... other cases
}
```

#### In StateMachine.BehaviorState

```swift
private struct BehaviorState {
    // ... existing fields
    var faceYaw: Double?        // NEW: Store latest yaw angle
}
```

#### In InteractionCoordinator

```swift
func isPersonLooking() -> Bool {
    guard let yaw = currentFaceYaw else { return false }
    return abs(yaw) <= 5.0  // ±5 degrees threshold
}
```

---

## Implementation Work Units

Below is a breakdown of discrete work units that can be assigned to AI coding agents.

### Work Unit 1: Filesystem Queue Infrastructure
**Estimated Complexity**: Medium
**Files to Create/Modify**:
- `RoboSantaApp/SpeechQueue/SpeechQueueConfiguration.swift` (new)
- `RoboSantaApp/SpeechQueue/ConversationSet.swift` (new)
- `RoboSantaApp/SpeechQueue/SpeechQueueManager.swift` (new)

**Requirements**:
1. Implement `SpeechQueueConfiguration` struct with defaults
2. Implement `ConversationSet` with folder validation
3. Implement `SpeechQueueManager` with:
   - Queue scanning (sorted by timestamp)
   - Oldest set consumption
   - Move to DONE folder (atomic operation)
   - Queue count tracking
   - DONE folder pruning (keep last N sets)
4. Add comprehensive error handling
5. Add unit tests for edge cases (malformed folders, missing files, etc.)

**Dependencies**: None

---

### Work Unit 2: Face Yaw Integration in Detection Pipeline
**Estimated Complexity**: Small
**Files to Modify**:
- `RoboSantaApp/Detection/DetectionRouter.swift`
- `RoboSantaApp/Figurine/StateMachine.swift`

**Requirements**:
1. Add `faceYaw: Double?` parameter to `StateMachine.Event.personDetected`
2. Update `DetectionRouter` to pass yaw from `DetectedFace.yawDeg`
3. Store yaw in `BehaviorState.faceYaw`
4. Ensure backward compatibility (yaw is optional)
5. Add logging for yaw values when `loggingEnabled`

**Dependencies**: None

---

### Work Unit 3: Minimal Idle Animation Mode
**Estimated Complexity**: Medium
**Files to Modify**:
- `RoboSantaApp/Figurine/StateMachine.swift`
- `RoboSantaApp/Figurine/StateMachineSettings.swift`

**Requirements**:
1. Add `minimalIdle(MinimalIdleConfiguration)` case to `IdleBehavior` enum
2. Implement `MinimalIdleConfiguration` struct
3. Add handling in `idleHeading()` method
4. Implement subtle head sway with configurable amplitude and period
5. Keep body stationary at center
6. Add default configuration in `StateMachineSettings`
7. Test smooth transitions between minimal idle and patrol modes

**Dependencies**: None

---

### Work Unit 4: Audio Player Component
**Estimated Complexity**: Medium
**Files to Create**:
- `RoboSantaApp/Audio/AudioPlayer.swift` (new)

**Requirements**:
1. Implement `AudioPlayer` class with `@Observable` macro
2. Support async playback of WAV files using AVAudioPlayer
3. Track playback state (idle/playing/completed/interrupted)
4. Implement `stop()` for interruption scenarios
5. Implement `waitForCompletion()` with proper cancellation support
6. Handle errors gracefully (file not found, unsupported format, etc.)
7. Clean up audio resources properly
8. Add volume control support
9. Ensure thread-safe state updates

**Dependencies**: None

---

### Work Unit 5: InteractionCoordinator Core
**Estimated Complexity**: Large
**Files to Create**:
- `RoboSantaApp/Coordination/InteractionCoordinator.swift` (new)
- `RoboSantaApp/Coordination/InteractionState.swift` (new)

**Requirements**:
1. Implement `InteractionState` enum with all states
2. Implement `InteractionCoordinator` class with `@Observable` macro
3. Subscribe to StateMachine detection updates (Combine publisher)
4. Monitor queue state via `SpeechQueueManager`
5. Implement state machine logic with proper state transitions
6. Implement `isPersonLooking()` using face yaw (±5°)
7. Command StateMachine idle behavior based on queue state
8. Track current conversation set and phrase progress
9. Add comprehensive logging for all state transitions
10. Handle edge cases:
    - Person lost during any phase
    - Queue emptied mid-interaction
    - Audio playback failures
11. Implement debouncing for person detection (require 1s tracking)
12. Add configurable thresholds (yaw tolerance, detection duration, etc.)

**Dependencies**: Work Units 1, 2, 3, 4

---

### Work Unit 6: Refactor SantaSpeaker for Queue-Based Generation
**Estimated Complexity**: Medium
**Files to Modify**:
- `RoboSantaApp/SantaSpeaker.swift`

**Requirements**:
1. Remove direct TTS playback (keep TTS generation)
2. Add `SpeechQueueManager` and `SpeechQueueConfiguration` dependencies
3. Refactor `runLoop()` to:
   - Check queue size before generating
   - Throttle generation based on config
   - Generate to timestamped folders
   - Create proper conversation set structure (start/middle*/end)
4. Save all WAV files to queue directory
5. Validate set completeness before returning
6. Add error recovery (partial generation cleanup)
7. Keep existing AI prompt templates and generation logic
8. Maintain Swedish language support
9. Add logging for generation progress

**Dependencies**: Work Unit 1

---

### Work Unit 7: Playback Integration in InteractionCoordinator
**Estimated Complexity**: Large
**Files to Modify**:
- `RoboSantaApp/Coordination/InteractionCoordinator.swift`

**Requirements**:
1. Implement conversation playback orchestration
2. Play `start.wav` on greeting state entry
3. Monitor playback completion and transition states
4. Play `middle*.wav` files sequentially with person-looking checks
5. Play `end.wav` conditionally (skip if person fully lost)
6. Handle interruptions gracefully:
   - Stop audio immediately on person lost
   - Move partial sets to DONE folder
   - Resume patrol/idle appropriately
7. Synchronize right hand gestures during middle phrases (optional emphasis)
8. Add timing logs for interaction analytics
9. Implement "still speaking" state flag
10. Ensure proper cleanup on cancellation

**Dependencies**: Work Units 4, 5

---

### Work Unit 8: StateMachine Detection Publisher
**Estimated Complexity**: Small
**Files to Modify**:
- `RoboSantaApp/Figurine/StateMachine.swift`

**Requirements**:
1. Add Combine framework import
2. Create `DetectionUpdate` struct with:
   - `personDetected: Bool`
   - `relativeOffset: Double`
   - `faceYaw: Double?`
   - `timestamp: Date`
3. Add `detectionPublisher: PassthroughSubject<DetectionUpdate, Never>`
4. Publish updates in `processEvents()` when person state changes
5. Include yaw from `BehaviorState.faceYaw`
6. Ensure thread-safe publishing (from workerQueue)
7. Add subscriber count tracking for diagnostics

**Dependencies**: Work Unit 2

---

### Work Unit 9: RuntimeCoordinator Integration
**Estimated Complexity**: Medium
**Files to Modify**:
- `RoboSantaApp/RuntimeCoordinator.swift`
- `RoboSantaApp/App.swift`

**Requirements**:
1. Instantiate `SpeechQueueManager` with default config
2. Instantiate `AudioPlayer`
3. Instantiate `InteractionCoordinator` with dependencies:
   - StateMachine
   - AudioPlayer
   - SpeechQueueManager
4. Update `SantaSpeaker` initialization with queue dependencies
5. Start all components in proper order:
   - StateMachine first
   - SantaSpeaker for background generation
   - InteractionCoordinator for orchestration
6. Ensure proper shutdown sequence
7. Wire up any UI controls for monitoring

**Dependencies**: Work Units 1, 4, 5, 6

---

### Work Unit 10: Configuration & Settings UI
**Estimated Complexity**: Small
**Files to Create/Modify**:
- `RoboSantaApp/UI/InteractionSettingsView.swift` (new, optional)
- Settings storage for persistence (optional)

**Requirements**:
1. Create configuration struct for tunable parameters:
   - Face yaw tolerance (default: 5.0)
   - Person detection duration threshold (default: 1.0s)
   - Queue size limits (min/max)
   - Generation throttle duration
   - Minimal idle animation parameters
2. Optional: SwiftUI view for runtime adjustment
3. Optional: Persist settings to UserDefaults
4. Ensure all components use centralized configuration

**Dependencies**: Work Units 1, 3, 5

---

### Work Unit 11: Testing & Integration
**Estimated Complexity**: Large
**Files to Create**:
- `RoboSantaTests/InteractionCoordinatorTests.swift` (new)
- `RoboSantaTests/SpeechQueueManagerTests.swift` (new)
- `RoboSantaTests/ConversationSetTests.swift` (new)

**Requirements**:
1. Create mock implementations:
   - Mock StateMachine (simulated person detection)
   - Mock AudioPlayer (instant playback)
   - Mock SpeechQueueManager (in-memory queue)
2. Test state machine transitions:
   - Idle → Patrolling (queue fills)
   - Patrolling → Greeting (person detected + looking)
   - Greeting → Conversing (start.wav complete + still looking)
   - Conversing → Farewell (middle phrases complete)
   - Any state → PersonLost (person leaves)
3. Test edge cases:
   - Person not looking (yaw > 5°)
   - Queue empties during patrol
   - Audio playback failure
   - Malformed conversation sets
4. Integration tests:
   - Full interaction flow end-to-end
   - Multiple rapid person detections
   - Queue overflow handling
5. Performance tests:
   - Queue scanning with 100+ sets
   - Memory usage during long runs

**Dependencies**: All previous work units

---

### Work Unit 12: Documentation & Logging
**Estimated Complexity**: Small
**Files to Create/Modify**:
- This file (IMPLEMENTATION.md) - keep updated
- `AGENTS.md` - reference this document

**Requirements**:
1. Document all new configuration parameters
2. Add inline code documentation for public APIs
3. Create troubleshooting guide for common issues:
   - Queue not filling
   - Person detection but no greeting
   - Audio not playing
4. Add telemetry/logging for:
   - Queue operations (add/consume/move to DONE)
   - State transitions with timestamps
   - Person engagement metrics (yaw, duration)
   - Playback events (start/complete/interrupt)
5. Create metrics dashboard (optional SwiftUI view)

**Dependencies**: None (ongoing)

---

## Configuration Recommendations

### Default Settings

```swift
// Queue Configuration
let defaultQueueConfig = SpeechQueueConfiguration(
    queueDirectory: URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("RoboSanta/SpeechQueue"),
    doneDirectory: URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("RoboSanta/SpeechQueue/DONE"),
    maxQueueSize: 20,
    minQueueSize: 5,
    generationThrottleSeconds: 180  // 3 minutes
)

// Interaction Configuration
let defaultInteractionConfig = InteractionConfiguration(
    faceYawToleranceDeg: 5.0,
    personDetectionDurationSeconds: 1.0,
    farewellSkipThresholdSeconds: 3.0,
    middlePhraseMaxDuration: 10.0  // Skip to next if person stops looking
)

// Minimal Idle Configuration
let defaultMinimalIdle = MinimalIdleConfiguration(
    centerHeading: 0,
    headSwayAmplitude: 3.0,
    headSwayPeriod: 8.0,
    bodyStillness: true
)
```

---

## Migration Strategy

Since this is a significant refactoring, here's a safe migration path:

### Phase 1: Infrastructure (Non-Breaking)
- Work Units 1, 4 (Queue manager, Audio player)
- These are new components with no existing dependencies
- Can be developed and tested independently

### Phase 2: StateMachine Enhancements (Backward Compatible)
- Work Units 2, 3, 8 (Face yaw, minimal idle, publisher)
- Add new features without breaking existing behavior
- Ensure old code paths still work

### Phase 3: New Orchestration (Feature Flag)
- Work Units 5, 6, 7 (InteractionCoordinator, refactored SantaSpeaker)
- Add feature flag to toggle between old and new behavior
- Test extensively with virtual detection source

### Phase 4: Integration & Testing
- Work Units 9, 10, 11 (RuntimeCoordinator, configuration, tests)
- Enable by default
- Monitor for issues

### Phase 5: Cleanup & Documentation
- Work Unit 12
- Remove old code paths
- Performance optimization

---

## Testing Strategy

### Unit Tests
- `ConversationSet` validation with malformed inputs
- `SpeechQueueManager` operations (scan/consume/move)
- State machine transition logic
- Face yaw threshold checking

### Integration Tests
- Full interaction flow with mock components
- Queue overflow and underflow scenarios
- Concurrent operations (generation + consumption)

### Manual Testing Checklist
1. ✓ Queue fills when empty
2. ✓ Santa idles when queue is empty (minimal animation)
3. ✓ Santa patrols when queue has content
4. ✓ Person detected triggers greeting (if looking)
5. ✓ Person not looking (yaw > 5°) → no greeting
6. ✓ Start phrase plays immediately on engagement
7. ✓ Middle phrases play only while person looking
8. ✓ Person stops looking → skip to farewell
9. ✓ Person leaves early → skip farewell
10. ✓ Farewell plays if person recently lost
11. ✓ Set moved to DONE after completion
12. ✓ Resume patrol/idle after interaction
13. ✓ Multiple people in quick succession
14. ✓ Generation continues in background
15. ✓ Queue size respected (max 20 sets)

---

## Performance Considerations

### Filesystem Operations
- **Queue scanning**: Only scan when state changes, not every loop
- **Atomic moves**: Use `FileManager.moveItem` for set consumption
- **Pruning**: Run DONE folder cleanup on background queue

### Memory Management
- **Audio buffering**: Release audio players after playback
- **Queue caching**: Cache scanned sets, invalidate on changes
- **Combine subscriptions**: Store in `cancellables` and cleanup properly

### Thread Safety
- **StateMachine**: Already uses dedicated queue
- **InteractionCoordinator**: Use `@MainActor` for UI state
- **File operations**: Use `DispatchQueue.global(qos: .utility)`

---

## Troubleshooting Guide

### Issue: Queue Not Filling

**Symptoms**: Santa stays in idle mode, no conversations generated

**Checks**:
1. Verify `SantaSpeaker.start()` is called
2. Check queue directory permissions
3. Check TTS service availability
4. Look for generation errors in logs
5. Verify AI integration (Apple Intelligence / Ollama) is working

**Fix**: Enable verbose logging in SantaSpeaker, check console output

---

### Issue: Person Detected but No Greeting

**Symptoms**: StateMachine tracks person but InteractionCoordinator doesn't trigger

**Checks**:
1. Verify face yaw angle is within ±5° (check logs)
2. Confirm person tracked for > 1 second
3. Check queue is not empty
4. Verify StateMachine publisher is emitting events
5. Check InteractionCoordinator state machine isn't stuck

**Fix**: Add breakpoints in `handleDetectionUpdate()`, verify yaw values

---

### Issue: Audio Not Playing

**Symptoms**: State transitions but no sound

**Checks**:
1. Verify WAV files exist at expected paths
2. Check audio device availability
3. Verify file format (WAV, proper encoding)
4. Check volume settings
5. Look for AudioPlayer errors in logs

**Fix**: Test WAV files with system audio player, verify file integrity

---

### Issue: State Machine Stuck in Conversing

**Symptoms**: Santa keeps trying to play middle phrases even though person left

**Checks**:
1. Verify `personLost` events are being sent by DetectionRouter
2. Check InteractionCoordinator subscription is active
3. Verify person loss detection timeout (0.6s threshold)
4. Check for race conditions in state updates

**Fix**: Add logging for all person lost events, verify timing

---

## Security & Safety Considerations

### File System Security
- **Path traversal**: Validate all folder names are pure timestamps
- **Disk space**: Monitor queue size and implement limits
- **Permissions**: Ensure queue directory is user-writable only

### Resource Limits
- **Memory**: Limit concurrent audio buffers (max 1-2)
- **CPU**: Throttle generation to avoid overheating
- **Disk I/O**: Batch filesystem operations where possible

### Servo Safety
- **Gesture coordination**: Don't override manual gesture commands
- **Cooldowns**: Respect existing hand cooldown logic
- **Stall guards**: Existing stall protection remains active

---

## Future Enhancements (Out of Scope)

These are potential improvements for future iterations:

1. **Dynamic Content**: Adjust conversation topics based on time of day, recent interactions
2. **Person Recognition**: Remember people who visited before
3. **Multi-Person Handling**: Prioritize among multiple people
4. **Emotion Detection**: Use face emotion to adjust tone
5. **Distance Awareness**: Different greetings based on proximity
6. **Queue Prioritization**: Mark some sets as "premium" for special occasions
7. **Telemetry Dashboard**: Real-time monitoring of interactions
8. **A/B Testing**: Compare different conversation templates
9. **Voice Cloning**: Different voices for variety
10. **Physical Feedback**: Add sensors for people actually standing still

---

## Success Criteria

The implementation is successful when:

1. ✅ Santa generates conversation sets continuously in the background
2. ✅ Filesystem queue acts as reliable buffer (20 sets typical)
3. ✅ Santa performs minimal idle animation when queue is empty
4. ✅ Santa patrols when queue has content
5. ✅ Person detection triggers greeting only if they're looking (±5° yaw)
6. ✅ Start phrase plays immediately after engagement
7. ✅ Middle phrases play sequentially while person is looking
8. ✅ Interaction gracefully handles person leaving at any time
9. ✅ Farewell plays only if person recently lost
10. ✅ Used sets moved to DONE folder atomically
11. ✅ System runs stably for hours without memory leaks
12. ✅ Clear logging enables easy debugging
13. ✅ All work units have passing tests
14. ✅ Documentation is complete and accurate

---

## Timeline Estimate

Assuming a single full-time developer or multiple AI coding agents:

- **Phase 1** (Infrastructure): 3-5 days
- **Phase 2** (StateMachine): 2-3 days
- **Phase 3** (Orchestration): 5-7 days
- **Phase 4** (Integration): 2-3 days
- **Phase 5** (Documentation): 1-2 days

**Total**: ~15-20 working days

With parallel AI agents working on independent units: ~5-7 days

---

## Appendix A: Complete File Structure

```
RoboSantaApp/
├── App.swift                               (modified: integration)
├── RuntimeCoordinator.swift                (modified: coordination setup)
├── SantaSpeaker.swift                      (modified: queue-based generation)
│
├── Audio/
│   └── AudioPlayer.swift                   (new)
│
├── Coordination/
│   ├── InteractionCoordinator.swift        (new)
│   ├── InteractionState.swift              (new)
│   └── InteractionConfiguration.swift      (new)
│
├── SpeechQueue/
│   ├── SpeechQueueConfiguration.swift      (new)
│   ├── ConversationSet.swift               (new)
│   └── SpeechQueueManager.swift            (new)
│
├── Detection/
│   ├── DetectionRouter.swift               (modified: pass yaw)
│   └── VisionDetectionSource.swift         (unchanged: already provides yaw)
│
├── Figurine/
│   ├── StateMachine.swift                  (modified: yaw param, publisher, minimal idle)
│   └── StateMachineSettings.swift          (modified: minimal idle config)
│
└── UI/
    └── InteractionSettingsView.swift       (new, optional)

RoboSantaTests/
├── InteractionCoordinatorTests.swift       (new)
├── SpeechQueueManagerTests.swift           (new)
└── ConversationSetTests.swift              (new)

~/RoboSanta/SpeechQueue/                    (runtime directory)
├── 20250327143022/
│   ├── start.wav
│   ├── middle1.wav
│   └── end.wav
└── DONE/
    └── 20250327142901/
        ├── start.wav
        └── end.wav
```

---

## Appendix B: Key Algorithms

### Queue Consumption Algorithm

```swift
func consumeOldestSet() -> ConversationSet? {
    let sets = scanQueue()
    guard let oldest = sets.first else { return nil }

    // Mark as in-progress to prevent concurrent consumption
    let inProgressURL = oldest.folderURL.appendingPathExtension("inprogress")
    try? FileManager.default.moveItem(at: oldest.folderURL, to: inProgressURL)

    return ConversationSet(folderURL: inProgressURL)
}

func moveToCompleted(_ set: ConversationSet) {
    let doneURL = config.doneDirectory.appendingPathComponent(set.id)
    try? FileManager.default.moveItem(at: set.folderURL, to: doneURL)
}
```

### Person Looking Detection

```swift
func isPersonEngaged(yaw: Double?, trackingDuration: TimeInterval) -> Bool {
    guard let yaw = yaw else { return false }
    guard trackingDuration >= config.minTrackingDuration else { return false }
    return abs(yaw) <= config.faceYawToleranceDeg
}
```

### Middle Phrase Playback Loop

```swift
func playMiddlePhrases() async -> Bool {
    for (index, middleFile) in currentSet.middleFiles.enumerated() {
        // Check person still looking before starting phrase
        guard isPersonLooking() else {
            log("Person stopped looking, skipping remaining middle phrases")
            return false
        }

        // Play full phrase (never interrupt mid-phrase)
        await audioPlayer.play(middleFile)

        // Check if completed or interrupted
        guard audioPlayer.state == .completed else {
            log("Playback interrupted during middle\(index + 1)")
            return false
        }
    }
    return true
}
```

---

**End of Implementation Design Document**

Version 1.0 | Created: 2025-03-27 | Author: Claude + Andreas Pardeike
