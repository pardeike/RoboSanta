# Pointing Hand Feature – Implementation Guide

This document provides a comprehensive guide for implementing the pointing hand feature in RoboSanta. It is designed to be followed by an AI agent to implement the feature without introducing regressions.

---

## Overview

### Feature Description

The RoboSanta figurine currently has a fully implemented left arm that waves. The right arm has a pointing hand that is only partially implemented (basic gestures exist but no coordinated interaction). This feature will add a new "point-and-lecture" interaction type that:

1. **Attention-grabbing phase**: The right arm raises halfway (forward pointing position) while playing a short attention-grabbing phrase (e.g., "Hey you", "Listen up", "You there" in Swedish)
2. **Lecture phase**: Once the attention phrase completes, the arm raises fully (finger pointing up) while playing a longer "lecture" phrase (a recommendation, humorous warning, or advice)

### Key Differences from Left Hand (Wave)

| Aspect | Left Hand (Wave) | Right Hand (Point) |
|--------|------------------|-------------------|
| Gesture type | Raise → Wave cycles → Lower | Raise halfway → Hold → Raise fully → Lower |
| Speech integration | Independent of specific speech | Tightly synchronized with two-phase speech |
| Cooldown | Has cooldown between waves | No cooldown (shorter, better integrated) |
| Trigger | Auto-triggered on person detection | Triggered as specific interaction type |
| Audio structure | Works with any conversation set | Requires specialized two-phase audio (attention + lecture) |

### System Flow

```
Person Detected → Queue has "pointing" set → 
  → Right arm raises to 0.5 (point forward)
  → Play attention.wav ("Hallå där!")
  → Right arm raises to 1.0 (point up)
  → Play lecture.wav ("Visste du att...")
  → Right arm lowers to 0
  → Conversation complete
```

---

## Strategic Design Decisions

### 1. ConversationSet File Structure Changes

**Current Structure** (requires `start.wav` + `end.wav`):
```
YYYYMMDDHHMMSS/
├── start.wav      (greeting/opening)
├── middle1.wav    (optional conversation)
├── middle2.wav    (optional)
├── ...
└── end.wav        (farewell)
```

**New Structure** (supports interaction type metadata):
```
YYYYMMDDHHMMSS/
├── type.txt       (NEW: contains "pointing", "greeting", "quiz", etc.)
├── start.wav      OR attention.wav (for pointing type)
├── middle*.wav    OR lecture.wav (for pointing type)
└── end.wav        (optional for some types)
```

**Key insight**: Instead of hardcoding the file detection logic for start/end, use a `type.txt` marker file to indicate the interaction type. This allows:

- Pointing sets: `type.txt` contains "pointing", has `attention.wav` and `lecture.wav`, no `end.wav` needed
- Pepp talk sets: `type.txt` contains "pepp", has `start.wav`, no `end.wav` needed (remove fake "Ha det bra!")
- Other sets: Keep existing structure

### 2. Refactored ConversationSet Validation

The `ConversationSet` struct needs to be extended to:
1. Read the interaction type from `type.txt`
2. Validate different required files based on type
3. Expose the interaction type to the coordinator

### 3. New Prompt Schema

A new schema in `PromptModels.swift` for generating pointing interaction content:

```swift
let pointingSchema = Model(
    name: "Pointing",
    description: "Din scen: Tomten pekar åt personen och ger ett kort råd eller varning.",
    properties: [
        Property(
            name: "attentionPhrase",
            description: "Ett eller två ord för att fånga uppmärksamheten. Mycket kort! Exempel: 'Hallå där!', 'Lyssna nu!', 'Du där!'",
            minLength: 2, maxLength: 20
        ),
        Property(
            name: "lecturePhrase", 
            description: "En kort rekommendation, skämtsam varning, eller råd. Något man säger medan man pekar med fingret uppåt.",
            minLength: 10, maxLength: 100
        ),
    ]
)
```

### 4. StateMachine Right Hand Autopilot

Following the pattern of `LeftHandAutoState`, create a `RightHandAutoState` enum and autopilot logic:

```swift
private enum RightHandAutoState: Equatable {
    case lowered
    case raisingHalf           // Moving to 0.5 position (point forward)
    case holdingHalf           // Waiting for attention phrase to complete
    case raisingFull           // Moving to 1.0 position (point up)
    case holdingFull           // Waiting for lecture phrase to complete
    case lowering              // Moving back to 0
}
```

**Key difference from left hand**: The right hand autopilot is driven by external "speech complete" signals, not by timers or wave cycles.

### 5. InteractionCoordinator Speech-Gesture Synchronization

The `InteractionCoordinator` needs to:
1. Detect "pointing" type conversation sets
2. Send right hand gesture commands at specific playback points
3. Wait for gesture completion before proceeding with audio

### 6. Removing Fake End.wav for Pepp Talk

The current pepp talk (case 0) generates a fake `end.wav` with "Ha det bra!". This should be removed since pepp talks should not have a farewell. This requires:
1. Marking the set as type "pepp" via `type.txt`
2. Having the coordinator skip farewell for pepp type sets

---

## Detailed Implementation Steps

### Step 1: Extend ConversationSet with Type Support

**File**: `RoboSantaApp/SpeechQueue/ConversationSet.swift`

1. Add an `InteractionType` enum:
```swift
enum InteractionType: String, Sendable {
    case greeting   // Standard greeting with start/middle/end
    case pepp       // Single phrase, no farewell needed
    case quiz       // Quiz format
    case joke       // Joke format
    case pointing   // Point-and-lecture format
    case unknown    // Fallback for legacy sets without type.txt
}
```

2. Add a `type` property to `ConversationSet`:
```swift
let type: InteractionType
```

3. Update the initializer to:
   - Read `type.txt` if it exists
   - Set appropriate file requirements based on type
   - For `pointing` type: require `attention.wav` and `lecture.wav` instead of `start.wav`/`end.wav`
   - For `pepp` type: only require `start.wav`, `end.wav` is optional

4. Add computed properties for pointing-specific files:
```swift
/// Path to attention phrase audio (pointing type only)
var attentionFile: URL? {
    guard type == .pointing else { return nil }
    return folderURL.appendingPathComponent("attention.wav")
}

/// Path to lecture phrase audio (pointing type only)
var lectureFile: URL? {
    guard type == .pointing else { return nil }
    return folderURL.appendingPathComponent("lecture.wav")
}

/// Whether this set has a farewell/end phrase
var hasEnd: Bool {
    switch type {
    case .pepp, .pointing: return false
    default: return FileManager.default.fileExists(atPath: endFile.path)
    }
}
```

### Step 2: Update SantaSpeaker Generation

**File**: `RoboSantaApp/SantaSpeaker.swift`

1. Add the pointing template near line 19:
```swift
let pointingTemplate = PromptTemplate(
    system: SantaSpeaker.baseSystem, 
    scene: "Tomten pekar åt personen för att ge ett kort råd eller en skämtsam varning."
)
```

2. Modify `generateConversationSet()` to:
   - Add case 4 for pointing interaction
   - Write `type.txt` file for ALL interaction types
   - For pointing: generate `attention.wav` and `lecture.wav` instead of start/end
   - For pepp: remove the fake "Ha det bra!" end.wav generation

3. Add helper to write type file:
```swift
private func writeTypeFile(_ type: String, to folder: URL) throws {
    let typeFile = folder.appendingPathComponent("type.txt")
    try type.write(to: typeFile, atomically: true, encoding: .utf8)
}
```

**Note**: Call this helper within the existing `do/catch` block of each case to ensure errors are properly handled.

4. Update case 0 (pepp) to:
```swift
case 0:
    interactionName = "pepp"
    print("🧠 Generating Pepp Talk (\(randomTopic))")
    struct PeppOut: Decodable { let happyPhrase: String }
    do {
        let r: PeppOut = try await thinker.generate(...)
        writeTypeFile("pepp", to: setFolder)
        await generateTTSToFile(setFolder.appendingPathComponent("start.wav"), r.happyPhrase)
        // NO end.wav - pepp talks don't have farewells
        success = true
    } catch { ... }
```

5. Add case 4 for pointing:
```swift
case 4:
    interactionName = "pointing"
    print("🧠 Generating Pointing (\(randomTopic))")
    struct PointOut: Decodable { let attentionPhrase, lecturePhrase: String }
    do {
        let r: PointOut = try await thinker.generate(
            template: pointingTemplate,
            topicAction: randomTopicAction,
            topic: randomTopic,
            model: pointingSchema,
            options: opts
        )
        writeTypeFile("pointing", to: setFolder)
        await generateTTSToFile(setFolder.appendingPathComponent("attention.wav"), r.attentionPhrase)
        await generateTTSToFile(setFolder.appendingPathComponent("lecture.wav"), r.lecturePhrase)
        success = true
    } catch { ... }
```

6. Update the random range to include pointing:
```swift
let interactionType = Int.random(in: 0...4)  // was 0...3
```

7. Add type.txt writing to ALL existing cases (greeting, quiz, joke) for consistency.

### Step 3: Add Pointing Schema to PromptModels

**File**: `RoboSantaApp/Integrations/PromptModels.swift`

Add after the existing schemas (around line 96):

```swift
let pointingSchema = Model(
    name: "Pointing",
    description: "Din scen: Tomten pekar åt personen för att dela ett kort råd eller en humoristisk varning. Håll det lekfullt!",
    properties: [
        Property(
            name: "attentionPhrase",
            description: "Mycket kort fras (1-3 ord) för att fånga uppmärksamheten. Exempel: 'Hallå du!', 'Psst!', 'Lyssna!', 'Du där!'",
            minLength: 2, maxLength: 25, disallowQuestion: true
        ),
        Property(
            name: "lecturePhrase",
            description: "En kort rekommendation, humoristisk varning eller visdomsord. Något man säger medan man pekar med fingret uppåt. Knyt an till ämnet.",
            minLength: 15, maxLength: 120
        ),
    ]
)
```

### Step 4: Extend StateMachine for Right Hand Autopilot

**File**: `RoboSantaApp/Figurine/StateMachine.swift`

1. Add the right hand auto state enum (around line 171):
```swift
private enum RightHandAutoState: Equatable {
    case lowered
    case raisingHalf           // Moving to 0.5 (forward point)
    case holdingHalf           // At 0.5, waiting for external signal
    case raisingFull           // Moving to 1.0 (up point)
    case holdingFull           // At 1.0, waiting for external signal
    case lowering              // Moving back to 0
}
```

2. Add state variables to `BehaviorState` (around line 243):
```swift
var rightHandAutoState: RightHandAutoState = .lowered
var rightHandTargetAngle: Double?
var rightHandMeasuredAngle: Double?
var rightHandLastLoggedAngle: Double?
```

3. Add new events for right hand control (in the Event enum):
```swift
case startPointingGesture      // Triggers raise to half position
case pointingAttentionDone     // Signal to raise to full position
case pointingLectureDone       // Signal to lower
```

4. Add right hand autopilot update method (following pattern of `updateLeftHandAutopilot`):
```swift
private func updateRightHandAutopilot(now: Date) {
    switch behavior.rightHandAutoState {
    case .lowered:
        // Waiting for startPointingGesture event
        break
        
    case .raisingHalf:
        // Position observer handles transition to holdingHalf
        break
        
    case .holdingHalf:
        // Waiting for pointingAttentionDone event
        break
        
    case .raisingFull:
        // Position observer handles transition to holdingFull
        break
        
    case .holdingFull:
        // Waiting for pointingLectureDone event
        break
        
    case .lowering:
        // Position observer handles transition to lowered
        break
    }
}
```

5. Add position observer handler for right hand (following pattern of `handleLeftHandPositionUpdate`):
```swift
private func handleRightHandPositionUpdate(angle: Double, now: Date) {
    guard let target = behavior.rightHandTargetAngle else { return }
    
    if hasReachedTarget(measured: angle, target: target) {
        switch behavior.rightHandAutoState {
        case .raisingHalf:
            behavior.rightHandAutoState = .holdingHalf
            logState("rightHand.holdingHalf")
            
        case .raisingFull:
            behavior.rightHandAutoState = .holdingFull
            logState("rightHand.holdingFull")
            
        case .lowering:
            behavior.rightHandAutoState = .lowered
            behavior.rightHandTargetAngle = nil
            behavior.rightGesture = .down
            logState("rightHand.lowered")
            
        default:
            break
        }
    }
}
```

6. Handle the new events in `processEvents()`:
```swift
case .startPointingGesture:
    if behavior.rightHandAutoState == .lowered {
        behavior.rightHandAutoState = .raisingHalf
        let halfPosition = configuration.rightHand.logicalRange.midPoint
        setRightHandTarget(angle: halfPosition, speed: settings.rightHandRaiseSpeed)
        logState("rightHand.raisingHalf")
    }

case .pointingAttentionDone:
    if behavior.rightHandAutoState == .holdingHalf {
        behavior.rightHandAutoState = .raisingFull
        let fullPosition = configuration.rightHand.logicalRange.upperBound
        setRightHandTarget(angle: fullPosition, speed: settings.rightHandRaiseSpeed)
        logState("rightHand.raisingFull")
    }

case .pointingLectureDone:
    if behavior.rightHandAutoState == .holdingFull {
        behavior.rightHandAutoState = .lowering
        let downPosition = configuration.rightHand.logicalRange.lowerBound
        setRightHandTarget(angle: downPosition, speed: settings.rightHandLowerSpeed)
        logState("rightHand.lowering")
    }
```

7. Add helper method for right hand target setting:
```swift
private func setRightHandTarget(angle: Double, speed: Double) {
    behavior.rightHandTargetAngle = angle
    behavior.rightHandLastLoggedAngle = nil
    rightHandDriver.setVelocity(speed)
    rightHandDriver.move(toLogical: angle)
    logState("rightHand.target", values: ["angle": angle, "speed": speed])
}
```

8. Wire up the position observer in init (similar to left hand):
```swift
rightHandDriver.setPositionObserver { [weak self] angle in
    guard let self else { return }
    self.workerQueue.async {
        self.behavior.rightHandMeasuredAngle = angle
        self.handleRightHandPositionUpdate(angle: angle, now: Date())
    }
}
```

9. Update `updatePose()` to call right hand autopilot:
```swift
updateRightHandAutopilot(now: now)
```

10. Update `rightHandValue()` to use measured position when available:
```swift
private func rightHandValue() -> Double {
    // Return the actual measured position if available (for smooth animation)
    if let measured = behavior.rightHandMeasuredAngle,
       behavior.rightHandAutoState != .lowered {
        return measured
    }
    // ... rest of existing code
}
```

### Step 5: Add Right Hand Settings to StateMachineSettings

**File**: `RoboSantaApp/Figurine/StateMachineSettings.swift`

1. Add settings for right hand (after left hand settings, around line 130):
```swift
/// Servo velocity (units/s) when raising the right hand.
/// Lower = slower, gentler raise; higher = faster response.
/// Typical: 50...300 (depends on servo limits).
let rightHandRaiseSpeed: Double

/// Servo velocity (units/s) when lowering the right hand.
/// Lower = gentle return; higher = quick drop.
/// Typical: 50...200 (depends on servo limits).
let rightHandLowerSpeed: Double

/// Tolerance (in normalized units) for considering right hand servo has reached target.
/// Typical: 0.01...0.05.
let rightHandPositionTolerance: Double
```

2. Add defaults in the `default` static property:
```swift
rightHandRaiseSpeed: 180,
rightHandLowerSpeed: 120,
rightHandPositionTolerance: 0.03,
```

3. Update `withFigurineConfiguration()` to include new settings.

### Step 6: Update InteractionCoordinator for Pointing

**File**: `RoboSantaApp/Coordination/InteractionCoordinator.swift`

1. Add a method to handle pointing interactions:
```swift
private func playPointingInteraction(set: ConversationSet) async -> Bool {
    guard let attentionFile = set.attentionFile,
          let lectureFile = set.lectureFile else {
        print("🎄 Invalid pointing set - missing files")
        return false
    }
    
    // Phase 1: Raise hand halfway and play attention phrase
    stateMachine.send(.startPointingGesture)
    
    // Small delay to let the arm start moving
    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
    
    // Play attention phrase while arm is rising/holding
    let attentionSuccess = await audioPlayer.play(attentionFile)
    guard attentionSuccess && !Task.isCancelled else {
        stateMachine.send(.pointingLectureDone) // Abort - lower hand
        return false
    }
    
    // Phase 2: Raise hand fully and play lecture phrase
    stateMachine.send(.pointingAttentionDone)
    
    // Small delay for transition
    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
    
    // Play lecture phrase while arm is raised
    let lectureSuccess = await audioPlayer.play(lectureFile)
    
    // Phase 3: Lower hand
    stateMachine.send(.pointingLectureDone)
    
    return lectureSuccess
}
```

2. Modify `startConversation()` to handle pointing type:
```swift
private func startConversation() async {
    guard let set = queueManager.consumeOldest() else { ... }
    
    currentSet = set
    currentSetId = set.id
    // ...
    
    // Handle different interaction types
    switch set.type {
    case .pointing:
        transition(to: .greeting, reason: "starting pointing interaction")
        isSpeaking = true
        let success = await playPointingInteraction(set: set)
        if !success {
            print("🎄 Pointing interaction failed")
        }
        // Pointing has no farewell
        await cleanupConversation()
        return
        
    case .pepp:
        // Pepp talk - just start phrase, no farewell
        transition(to: .greeting, reason: "starting pepp talk")
        isSpeaking = true
        let success = await audioPlayer.playStart(of: set)
        // Pepp has no farewell
        await cleanupConversation()
        return
        
    default:
        // Standard flow for greeting, quiz, joke
        // ... existing code ...
    }
}
```

3. Update farewell logic to check `hasEnd`:
```swift
// Play farewell if person is still around AND set has an end
if (personTracked || isRecentlyLost()) && (currentSet?.hasEnd ?? false) {
    await playFarewell()
}
```

### Step 7: Update InteractionState (Optional)

**File**: `RoboSantaApp/Coordination/InteractionState.swift`

Add pointing-specific states if needed for detailed logging:
```swift
/// Playing attention phrase (pointing interaction)
case pointingAttention

/// Playing lecture phrase (pointing interaction)
case pointingLecture
```

### Step 8: Add Extension for ClosedRange midPoint

**File**: `RoboSantaApp/SharedExtensions.swift` (or inline in StateMachine)

```swift
extension ClosedRange where Bound == Double {
    var midPoint: Double {
        (lowerBound + upperBound) / 2
    }
}
```

---

## Testing Checklist

### Unit Testing (if infrastructure exists)

1. [ ] ConversationSet correctly parses type.txt
2. [ ] ConversationSet validates pointing files correctly
3. [ ] ConversationSet.hasEnd returns correct values per type
4. [ ] Right hand autopilot state transitions work correctly

### Integration Testing

1. [ ] Generate a pointing conversation set
2. [ ] Verify attention.wav and lecture.wav are created
3. [ ] Verify type.txt contains "pointing"
4. [ ] Play pointing set and verify arm movements sync with audio
5. [ ] Verify no farewell is played for pointing sets

### Regression Testing

1. [ ] Existing greeting sets still work
2. [ ] Existing quiz sets still work
3. [ ] Existing joke sets still work
4. [ ] Pepp talk sets work without fake "Ha det bra!" farewell
5. [ ] Left hand waving still works independently
6. [ ] Queue management still works correctly
7. [ ] Person detection still triggers interactions

### Hardware Testing

1. [ ] Right arm moves to halfway position smoothly
2. [ ] Right arm moves to full position smoothly
3. [ ] Right arm returns to down position smoothly
4. [ ] No mechanical binding or jerky motion
5. [ ] Timing feels natural with speech

---

## Risk Mitigation

### Potential Issues and Solutions

1. **Risk**: ConversationSet breaking for legacy sets without type.txt
   - **Solution**: Default to `unknown` type which behaves like current `greeting` type

2. **Risk**: Right hand servo limits different from left hand
   - **Solution**: Use existing configuration values, tune speeds independently

3. **Risk**: Race condition between audio completion and gesture signals
   - **Solution**: Audio completes before sending gesture signal; small delays allow movement

4. **Risk**: Person lost during pointing interaction
   - **Solution**: Abort cleanly by sending `pointingLectureDone` to lower arm

5. **Risk**: Queue validation rejecting pointing sets
   - **Solution**: Update validation to recognize pointing-specific files

---

## File Change Summary

| File | Changes |
|------|---------|
| `SpeechQueue/ConversationSet.swift` | Add InteractionType, type.txt parsing, hasEnd, pointing file accessors |
| `SantaSpeaker.swift` | Add pointing template, case 4 generation, write type.txt for all cases, remove fake end.wav for pepp |
| `Integrations/PromptModels.swift` | Add pointingSchema |
| `Figurine/StateMachine.swift` | Add RightHandAutoState, events, autopilot logic, position observer |
| `Figurine/StateMachineSettings.swift` | Add rightHandRaiseSpeed, rightHandLowerSpeed, rightHandPositionTolerance |
| `Coordination/InteractionCoordinator.swift` | Add playPointingInteraction(), update startConversation() for types |
| `SharedExtensions.swift` | Add ClosedRange.midPoint (if not exists) |

---

## Implementation Order

For minimal risk of regressions, implement in this order:

1. **PromptModels.swift** - Add schema (no runtime impact)
2. **StateMachineSettings.swift** - Add settings (no runtime impact)
3. **ConversationSet.swift** - Add type support with backward compatibility
4. **StateMachine.swift** - Add right hand autopilot (disabled until triggered)
5. **SantaSpeaker.swift** - Add pointing generation and type.txt
6. **InteractionCoordinator.swift** - Wire everything together

Each step can be tested independently before moving to the next.
