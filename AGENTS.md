# AGENTS.md - Guide for AI Agents Working on RoboSanta

This document provides context, patterns, and best practices for AI coding agents working on the RoboSanta codebase.

## 🎯 Project Context

**What is RoboSanta?**
An interactive Santa Claus animatronic figurine for office corridors that:
- Detects and tracks people using computer vision
- Generates conversational Swedish text using AI
- Speaks using text-to-speech
- Controls physical servos for head, body, and hand movements

**Technology**: Swift 5, macOS, Phidget hardware, Python TTS, Apple Vision framework

**Key Goal**: Entertain people walking by with engaging, AI-generated interactions in Swedish.

## 🏗️ Architecture Understanding

### Component Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                        App.swift                             │
│  (Entry point, AI generation loop, template configs)        │
└────────────┬────────────────────────────────────────────────┘
             │
        ┌────┴────┬──────────────┬──────────────────┐
        │         │              │                  │
   ┌────▼───┐ ┌──▼──────┐ ┌─────▼──────┐ ┌────────▼────────┐
   │ Camera │ │ State   │ │ AI         │ │ TTS            │
   │ Manager│ │ Machine │ │ Integrations│ │ Services       │
   └────────┘ └─────────┘ └────────────┘ └─────────────────┘
        │         │              │                  │
   [Vision]   [Servos]      [Protocols]      [Audio/Network]
```

### Data Flow

1. **Person Detection** (CameraManager → StateMachine):
   ```
   Camera → Vision API → Face Detection → 
   Compute Offset → StateMachine.send(.personDetected)
   ```

2. **Servo Control** (StateMachine → Hardware):
   ```
   Event → Update State → Calculate Pose → 
   Send to Servos → Hardware Movement
   ```

3. **AI Generation** (App → Think → Voice):
   ```
   Template + Topic → AI Generate → 
   TTS Synthesize → Audio Playback
   ```

## 📂 File Organization

### Critical Files for Understanding

1. **App.swift** (180 lines)
   - Entry point and orchestration
   - AI integration selection
   - Content generation loop
   - Prompt template definitions

2. **StateMachine.swift** (1493 lines) ⚠️ LARGE
   - Core control logic for servos
   - Person tracking algorithms
   - Gesture state management
   - Most complex file in project

3. **CameraManager.swift** (308 lines)
   - Face detection using Vision
   - Offset calculation for tracking
   - Integration with StateMachine

4. **Tools.swift** (146 lines)
   - `Think` and `SantaVoice` protocols
   - Helper functions (keychain lookup, text cleanup, quiz fixing)

5. **Integrations/Shared.swift** (51 lines)
   - Prompt templates
   - Provider-agnostic generation options
   - JSON schema helpers for Ollama formatting

6. **Models/** (`Model.swift`, `Property.swift`)
   - Schema definitions for Apple FoundationModels dynamic generation

### Directory Structure

- **Figurine/**: Hardware control and state management
- **Integrations/**: External API clients (AI, TTS)
- **Phidget22/**: Auto-generated hardware bindings (don't modify)
- **Models/, Phrases/, Voices/**: Data and resources

## 🎨 Code Patterns and Conventions

### 1. Protocol-Oriented Design

The project uses protocols for abstraction:

```swift
protocol Think {
    func generate<T: Decodable>(
        template: PromptTemplate,
        topicAction: String,
        topic: String,
        model: Model,
        options: GenerationOptions
    ) async throws -> T
}

protocol SantaVoice {
    func tts(_ file: String, _ text: String) async
    func speak() async
}
```

**When adding new integrations**, implement these protocols.

### 2. Event-Driven State Machine

StateMachine uses events to trigger state changes:

```swift
enum Event: Equatable {
    case idle
    case aimCamera(Double)
    case personDetected(relativeOffset: Double)
    case personLost
    case setLeftHand(LeftHandGesture)
    case setRightHand(RightHandGesture)
    case setIdleBehavior(IdleBehavior)
    // ...
}

// Usage:
santa.send(.personDetected(relativeOffset: -0.3))
```

**When adding behavior**, define new events and handle in `processEvents()`.

### 3. Async/Await Throughout

Modern Swift concurrency is used extensively:

```swift
func generate(...) async throws -> T { }
func tts(_ file: String, _ text: String) async { }
await voice.speak()
```

**Always use async/await**, avoid completion handlers.

### 4. MainActor for UI/State

Several types are marked `@MainActor`:

```swift
@MainActor
struct AppleIntelligence: Think { }
```

**Respect actor boundaries** when working with these types.

### 5. Configuration Through Structs

Settings are centralized in immutable structs:

```swift
struct Settings {
    let loggingEnabled: Bool
    let centerHoldOffsetNorm: Double
    // ... ~30 tunable parameters
}
```

**Don't hardcode values**, use Settings struct.

## 🔧 Common Tasks Guide

### Adding a New AI Integration

**Template:**

```swift
// File: Integrations/MyAI.swift
import Foundation
import FoundationModels

@MainActor
struct MyAI: Think {
    let apiKey: String
    let baseURL: String
    
    func generate<T: Decodable>(
        template: PromptTemplate,
        topicAction: String,
        topic: String,
        model: Model,
        options: GenerationOptions
    ) async throws -> T {
        // 1. Render prompt
        let (system, user) = template.render(topicAction: topicAction, topic: topic)
        
        // 2. Build request to your API
        // ...
        
        // 3. Parse response and decode to T
        return try JSONDecoder().decode(T.self, from: responseData)
    }
}

// Update App.swift:
// static let thinker: Think = MyAI(apiKey: "...", baseURL: "...")
```

### Adding a New Gesture

**Steps:**

1. Define gesture in StateMachine:
```swift
enum LeftHandGesture: Equatable {
    case myNewGesture(speed: Double)
    // ...
}
```

2. Handle in state machine:
```swift
private func leftHandValue(deltaTime: TimeInterval) -> Double {
    switch behavior.leftGesture {
    case .myNewGesture(let speed):
        // Calculate servo position
        return calculatedPosition
    // ...
    }
}
```

3. Trigger from event:
```swift
santa.send(.setLeftHand(.myNewGesture(speed: 1.5)))
```

### Adding a New Interaction Type

**Template:**

1. Define schema in `PromptModels.swift`:
```swift
let myInteractionSchema = Model(
    name: "MyInteraction",
    description: "Description of interaction type",
    properties: [
        Property(name: "field1", description: "What this field contains"),
        Property(name: "field2", description: "What this field contains"),
    ]
)
```

2. Add template in `App.swift`:
```swift
static let myTemplate = PromptTemplate(
    system: baseSystem,
    scene: "Santa does something specific."
)
```

3. Add to background loop in `App.swift`:
```swift
case X:
    print("🧠 My Interaction")
    struct MyOut: Decodable { let field1, field2: String }
    do {
        let r: MyOut = try await thinker.generate(
            template: myTemplate,
            topicAction: randomTopicAction,
            topic: randomTopic,
            model: myInteractionSchema,
            options: opts
        )
        await voice.tts("Part1", r.field1)
        await voice.tts("Part2", r.field2)
    } catch {
        print(error)
    }
```

### Modifying Tracking Behavior

**Key method**: `StateMachine.updateTrackingHeading()`

**Key parameters** in `StateMachineSettings.swift`:
- `centerHoldOffsetNorm`: Deadzone before body moves
- `maxJumpDeg`: Maximum acceptable face position jump
- `headRateCapDegPerSec`: Head rotation speed limit
- `bodyRateCapDegPerSec`: Body rotation speed limit

**Approach:**
1. Understand the tracking pipeline in `updateTrackingHeading()`
2. Modify parameters in Settings first
3. Only change algorithm if parameter tuning insufficient
4. Test with real hardware if possible

### Adding Logging/Telemetry

**Pattern:**

```swift
// Event logging (timestamped, JSON)
logEvent("my.event", values: [
    "param1": value1,
    "param2": value2
])

// State logging (console output)
logState("my.state.label", values: [
    "key": "value"
])
```

**Location**: Both methods in `StateMachine` class, controlled by `loggingEnabled` setting.

## ⚠️ Important Warnings

### 1. Don't Modify Phidget22 Files

The `Phidget22/` directory contains auto-generated bindings. **Never edit these directly.**

If you need to change hardware behavior, work in:
- `Figurine/StateMachine.swift`
- `Figurine/Functions.swift`
- `Figurine/Handlers.swift`

### 2. Force Unwrapping Issues

There are still `try!` calls when building Ollama option maps and JSON schemas (e.g., `Integrations/OllamaThink.swift`, `Integrations/Shared.swift`). They are likely safe but will crash on unexpected input; prefer regular `try` if touching those paths.

### 3. Hardcoded Paths

Python path is hardcoded:
```swift
process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3.11")
```

**Be aware** this will break on non-Homebrew systems. Consider making configurable if changing TTS code.

### 4. StateMachine Complexity

`StateMachine.swift` is 1493 lines and handles:
- Servo control
- Face tracking
- Gesture management
- Idle behaviors
- Stall detection
- Telemetry

**When modifying**, be extremely careful about side effects. Consider extracting functionality if adding more.

### 5. Swedish Language Hardcoding

All prompts are in Swedish:
```swift
static let baseSystem = """
Du är en svensk copywriter. Skriv kort och oväntat, lite roligt.
...
```

**If adding prompts**, maintain Swedish unless explicitly changing language support.

## 🧪 Testing Strategy

### Current State
- ⚠️ No unit tests exist
- Testing is manual with hardware
- No mocking infrastructure

### Recommended Approach When Making Changes

1. **For StateMachine changes**:
   - Test with hardware if available
   - Log state changes verbosely
   - Verify servo positions are within safe ranges

2. **For AI integration changes**:
   - Test with small, controlled inputs
   - Verify JSON parsing works
   - Check error handling paths

3. **For TTS changes**:
   - Test audio output quality
   - Verify cleanup of temporary files
   - Check for memory leaks in long runs

### Creating Tests (Future)

If adding test infrastructure:

```swift
// Example test structure
import XCTest
@testable import RoboSanta

class StateMachineTests: XCTestCase {
    func testPersonDetectionTriggersTracking() {
        // Mock hardware
        let mockConfig = FigurineConfiguration.default
        let sm = StateMachine(configuration: mockConfig)
        
        // Send event
        sm.send(.personDetected(relativeOffset: 0.5))
        
        // Verify behavior
        // ...
    }
}
```

## 📐 Code Organization Best Practices

### File Size Guidelines

- **Target**: < 500 lines per file
- **Warning**: > 800 lines (consider splitting)
- **Critical**: > 1500 lines (definitely split)

`StateMachine.swift` at 1493 lines needs refactoring (see TODO.md).

### Naming Conventions

- **Types**: PascalCase (`StateMachine`, `CameraManager`)
- **Functions**: camelCase (`updatePose`, `processEvents`)
- **Properties**: camelCase (`leftHandGesture`, `isRunning`)
- **Constants**: camelCase with `let` (`baseSystem`, `tempSantaDir`)
- **Protocols**: PascalCase, often nouns (`Think`, `SantaVoice`)

### Comment Style

The codebase uses:

1. **Section markers**:
```swift
// MARK: - Lifecycle
// MARK: - Servo wrapper
```

2. **Inline documentation** for complex logic:
```swift
// Gain scheduling: smaller gains near center during tracking
let offMag = abs(behavior.lastFaceOffset ?? 1.0)
```

3. **TODO comments** (though prefer TODO.md):
```swift
// TODO: Add input validation
```

**When adding code**, follow these patterns.

## 🎓 Understanding Key Algorithms

### Face Tracking Algorithm

**Location**: `StateMachine.updateTrackingHeading()`

**Purpose**: Convert camera-space face position to absolute servo heading.

**Flow**:
1. Compute normalized offset (-1 to +1) from camera center
2. Apply low-pass filter (EMA) to reduce jitter
3. Calculate velocity in camera space
4. Apply predictive lead based on velocity
5. Blend prediction with measurement
6. Update tracking heading

**Key insight**: Uses predictive tracking to anticipate movement, with center deadzone to prevent oscillation.

### Servo Control Algorithm

**Location**: `StateMachine.updateHeadAndBodyTargets()`

**Purpose**: Distribute camera heading across head and body servos smoothly.

**Flow**:
1. Calculate head share of rotation (varies by context)
2. Apply rate limiting for smooth motion
3. Freeze body near center during tracking (reduces wobble)
4. Gradually hand off head deflection to body (recentering)
5. Apply stall guard to prevent fighting limits

**Key insight**: Two-servo system shares rotation, with body following slowly and head handling fine tracking.

### Gesture State Machine

**Location**: `StateMachine.updateLeftHandAutopilot()`

**Purpose**: Automatically raise, wave, and lower hand when tracking people.

**States**:
- `lowered`: Hand down, waiting for person
- `raising`: Moving to up position
- `waving`: Performing wave cycles
- `pausingAtTop`: Holding up position
- `lowering`: Returning to down position
- Cooldown period between gestures

**Key insight**: Fully automated gesture based on tracking duration, with cooldown to prevent spam.

## 🔍 Debugging Tips

### Console Output Patterns

**Tracking events**:
```
[state] event.personDetected
[state] mode.tracking
[state] tracking.face meas=45.2 pred=46.1 off=0.23
```

**Servo commands**:
```
[state] leftHand.raising
[state] leftHand.target angle=0.8 speed=100
[state] leftHand.reached angle=0.82
```

**Errors**:
```
### ERROR 12: Device not attached
```

### Common Issues and Fixes

1. **"TTS server not ready"**
   - Check Python installation
   - Verify tts-server.py can run standalone
   - Check port 8080 not in use

2. **Servo not moving**
   - Check `loggingEnabled = true` to see servo commands
   - Verify attachment events in console
   - Check servo engaged: `try ch.setEngaged(true)`

3. **Face detection not working**
   - Check camera permissions
   - Verify `hasActiveFace` state changes in logs
   - Check Vision framework not throwing errors

4. **AI generation failing**
   - Enable verbose error logging
   - Check API key configuration
   - Try switching to AppleIntelligence (no API needed)

## 📦 Dependencies

### Swift Dependencies (via Xcode project)
- **FoundationModels**: Apple's on-device AI
- **Ollama**: Local LLM integration
- **AVFoundation**: Camera and audio
- **Vision**: Face detection
- Custom Phidget framework (included)

### Python Dependencies (for TTS server)
- torch
- torchaudio
- transformers
- diffusers
- chatterbox

### System Dependencies
- macOS 14+ (for FoundationModels)
- Python 3.11
- Homebrew (for Python installation)

## 🚀 Making Your First Change

**Recommended starter tasks:**

1. **Add a new random topic** (`PromptModels.swift`):
   - Add string to `randomTopics` array
   - Test by observing generated content

2. **Adjust tracking sensitivity** (`StateMachineSettings.swift`):
   - Modify `centerHoldOffsetNorm` value
   - Test with hardware or logs

3. **Add logging to understand flow**:
   - Add `logState()` calls in key methods
   - Observe behavior in console

4. **Create a new prompt template** (`App.swift`):
   - Follow existing template patterns
   - Test generation loop

**Avoid as first change:**
- Modifying StateMachine core logic
- Changing servo communication
- Refactoring Phidget code
- Rewriting tracking algorithms

## 📚 Additional Resources

- **Swift Concurrency**: Understanding async/await is crucial
- **AVFoundation**: For camera and audio work
- **Vision Framework**: For face detection details
- **Phidget Documentation**: For hardware specifics

## ✅ Checklist for AI Agents

Before making changes:
- [ ] Read relevant section of TODO.md
- [ ] Understand affected component's responsibility
- [ ] Check for existing patterns to follow
- [ ] Consider impact on hardware (if applicable)
- [ ] Plan error handling strategy

When making changes:
- [ ] Follow existing code style
- [ ] Add logging for new behaviors
- [ ] Update documentation if public API changes
- [ ] Consider edge cases
- [ ] Test with console output at minimum

After making changes:
- [ ] Verify no force unwraps added
- [ ] Check for potential crashes
- [ ] Ensure async/await used correctly
- [ ] Update TODO.md if addressing items
- [ ] Document any new configuration needed

## 🤝 Agent Collaboration

If multiple agents working together:

1. **Coordinate on StateMachine.swift**: Highest conflict risk
2. **Own specific integration files**: Less conflict
3. **Communicate configuration changes**: Affects everyone
4. **Share testing findings**: Hardware behavior important

## 📞 Getting Help

When stuck:
1. Check TODO.md for known issues
2. Review similar code patterns in codebase  
3. Enable verbose logging to understand behavior
4. Test incrementally with small changes
5. Ask human maintainer for hardware-specific questions

## 🧰 CLI Build & Run (Codex default)
- Stay in repo root; use full Xcode via env var: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
- Build debug app: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme RoboSantaApp -project RoboSanta.xcodeproj -configuration Debug -destination 'platform=macOS' -derivedDataPath build build`
- Launch with terminal logs: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./build/Build/Products/Debug/RoboSanta.app/Contents/MacOS/RoboSanta` (or `open ./build/Build/Products/Debug/RoboSanta.app`)
- Optional one-time switch: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` to drop the env var; needs admin.
- Requires logged-in macOS session for camera/USB permissions; no headless support.
- Async run + logging to `robo-run.log` from repo root:
  - Clear log: `: > robo-run.log`
  - Start unified log stream to file: `/usr/bin/log stream --style compact --process RoboSanta > robo-run.log & echo $! > .robo-log.pid`
  - Launch app (append stdout/stderr to same file): `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer nohup ./build/Build/Products/Debug/RoboSanta.app/Contents/MacOS/RoboSanta >> robo-run.log 2>&1 & echo $! > .robo-app.pid`
  - Watch logs: `tail -f robo-run.log`
  - Stop: `kill $(cat .robo-app.pid) $(cat .robo-log.pid)` (or kill PIDs printed by the start commands)

---

**Remember**: This is a physical hardware project. Be cautious with changes that affect servo movement - incorrect commands could damage hardware or cause unexpected physical behavior.

Good luck, and may your pull requests be ever in your favor! 🎅
