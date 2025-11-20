# TODO - Code Review and Refactoring Tasks

This document outlines bugs, code quality issues, and refactoring opportunities identified in the RoboSanta codebase. These improvements will enhance maintainability and make it easier for AI agents to work with the code.

## 🐛 Critical Bugs

### 1. Force Unwrapping and Optional Handling
**Location**: `RoboSantaApp/Integrations/RoboSantaTTS.swift:85-86`
```swift
let player = try! AVAudioPlayer(contentsOf: file)
```
**Issue**: Force try (`try!`) will crash the app if the audio file is missing or corrupted.
**Fix**: Use proper error handling with try-catch or optional binding.
**Priority**: HIGH

### 2. Hardcoded Python Path
**Location**: `RoboSantaApp/Integrations/TTSServer.swift:39`
```swift
process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3.11")
```
**Issue**: Hardcoded path will fail on systems without Homebrew or with different Python installations.
**Fix**: Use a discovery mechanism or configurable path, check common locations.
**Priority**: HIGH

### 3. Unsafe Force Casting
**Location**: `RoboSantaApp/Figurine/Handlers.swift:5`
```swift
let attachedDevice = sender as! RCServo
```
**Issue**: Force cast will crash if sender is not an RCServo.
**Fix**: Use conditional casting with guard/if-let.
**Priority**: MEDIUM

### 4. Missing Error Propagation
**Location**: `RoboSantaApp/Integrations/ElevenLabs.swift:72-78`
**Issue**: Network errors are silently swallowed with try?.
**Fix**: Log errors properly or propagate them for handling.
**Priority**: MEDIUM

## 🔧 Code Quality Issues

### 1. Code Duplication - OpenAI and Koala Implementations
**Location**: `RoboSantaApp/Integrations/OpenAI.swift` and `Koala.swift`
**Issue**: These files are nearly identical (~90% duplicate code). Only difference is error enum names.
**Refactor**: 
- Create a generic `OpenAICompatibleAPI` base implementation
- Have both `OpenAI` and `Koala` inherit/compose from the base
- Use dependency injection for configuration differences
**Impact**: Reduces maintenance burden, easier to fix bugs once
**Priority**: HIGH

### 2. Commented Out Code
**Location**: Multiple files
- `App.swift:128-168` - Large block of commented servo control code
- `App.swift:38-43` - Commented integration choices
- `CameraManager.swift:104-175` - Commented camera tuning methods
**Issue**: Dead code clutters the codebase and confuses intent.
**Refactor**: Remove completely or move to documentation/examples.
**Priority**: MEDIUM

### 3. Magic Numbers
**Location**: Throughout `StateMachine.swift`
```swift
if remainder < 3 {
    minute -= remainder
} else {
    minute += (5 - remainder)
}
```
**Issue**: Unclear purpose of magic numbers like 3, 5, 0.12, 0.5, etc.
**Refactor**: Extract to named constants with clear documentation.
**Priority**: MEDIUM

### 4. Inconsistent Error Handling
**Issue**: Mix of three different error handling strategies:
- Force unwrap with `try!`
- Optional try with `try?`
- Proper try-catch blocks
**Refactor**: Establish consistent error handling patterns across the codebase.
**Priority**: MEDIUM

### 5. Mixed Responsibilities in App.swift
**Location**: `RoboSantaApp/App.swift`
**Issue**: Single file contains:
- App initialization
- Template definitions
- AI integration configuration
- Background loop logic
**Refactor**: Split into separate files:
- `AppConfiguration.swift` - Configuration and setup
- `PromptTemplates.swift` - All prompt templates
- `ContentGenerator.swift` - Background generation loop
**Priority**: HIGH

## 🏗️ Architecture Improvements

### 1. Hardcoded Configuration
**Location**: Multiple files
- API URLs in `OpenAI.swift` and `Koala.swift`
- Voice IDs in `ElevenLabs.swift`
- TTS server details in multiple files
**Refactor**: 
- Create `Configuration.swift` with environment-based settings
- Support .env file or plist for configuration
- Use dependency injection for testability
**Priority**: HIGH

### 2. Tight Coupling to External Services
**Issue**: Direct dependencies on specific AI services make switching difficult.
**Refactor**:
- Define clear protocol boundaries (`Think`, `SantaVoice` are good starts)
- Use factory pattern for service instantiation
- Add service health checks and fallback mechanisms
**Priority**: MEDIUM

### 3. Global State
**Location**: `App.swift:6`
```swift
let santa = StateMachine()
```
**Issue**: Global mutable state makes testing difficult and can cause race conditions.
**Refactor**: Pass StateMachine through dependency injection or environment objects.
**Priority**: MEDIUM

### 4. Missing Abstraction for Phidget Hardware
**Issue**: Direct hardware calls scattered throughout code.
**Refactor**: Create a hardware abstraction layer:
- Define `HardwareController` protocol
- Implement `PhidgetController` for production
- Create `MockHardwareController` for testing
**Impact**: Enables development and testing without physical hardware.
**Priority**: HIGH

## 📝 Documentation Needs

### 1. Missing API Documentation
**Issue**: Public interfaces lack documentation comments.
**Action**: Add comprehensive documentation:
- Protocol requirements
- Method parameters and return values
- Error cases
- Usage examples
**Priority**: HIGH

### 2. Configuration Documentation
**Issue**: No clear guide on required environment setup.
**Action**: Document:
- Required Python packages and versions
- Homebrew dependencies
- API key configuration
- Hardware setup requirements
**Priority**: HIGH

### 3. Architecture Documentation
**Issue**: No high-level architecture diagram or explanation.
**Action**: Create documentation showing:
- Component interaction diagram
- State machine behavior
- Data flow through the system
- Integration points
**Priority**: MEDIUM

## 🧪 Testing Gaps

### 1. No Unit Tests
**Issue**: Zero test coverage makes refactoring risky.
**Action**: 
- Set up XCTest framework
- Add tests for core logic (StateMachine, prompt generation)
- Mock external dependencies
**Priority**: HIGH

### 2. No Integration Tests
**Issue**: No way to verify hardware integration without physical setup.
**Action**: Create integration test suite with mocks.
**Priority**: MEDIUM

### 3. No CI/CD Pipeline
**Issue**: No automated build or test verification.
**Action**: Set up GitHub Actions for:
- Build verification
- Test execution
- Code quality checks
**Priority**: MEDIUM

## 🔒 Security Issues

### 1. API Key Storage
**Location**: `Tools.swift:22-45`
**Issue**: Keys retrieved from Keychain but no validation or encryption details.
**Action**: 
- Document key storage requirements
- Add key rotation support
- Implement key validation on retrieval
**Priority**: MEDIUM

### 2. Hardcoded API Credentials
**Location**: `OpenAI.swift:12`, `Koala.swift:12`
```swift
apiKey: String = "none"
```
**Issue**: Default "none" value could lead to silent failures.
**Action**: Require explicit API key configuration or fail fast.
**Priority**: LOW

### 3. No Input Validation
**Location**: Throughout integration code
**Issue**: User input (text, topics) not validated before sending to APIs.
**Action**: Add input sanitization and validation.
**Priority**: LOW

## 🎯 Performance Optimizations

### 1. Inefficient String Operations
**Location**: `Tools.swift:115-128`
**Issue**: Multiple string replacements and character filtering.
**Refactor**: Use single pass with reduce or more efficient algorithm.
**Priority**: LOW

### 2. Synchronous Audio Playback
**Location**: `ElevenLabs.swift:76-77`
```swift
while player.isPlaying { usleep(100000) }
```
**Issue**: Polling with sleep is inefficient.
**Refactor**: Use completion handlers or async/await properly.
**Priority**: LOW

### 3. Unbounded Buffer Growth
**Location**: `TTSServer.swift:197-199`
```swift
if stdoutBuffer.count > 8192 {
    stdoutBuffer.removeFirst(stdoutBuffer.count - 8192)
}
```
**Issue**: Buffer can grow to 8KB before trimming.
**Refactor**: Use circular buffer or more efficient data structure.
**Priority**: LOW

## 🤖 AI Agent Friendliness Improvements

### 1. Improve Code Organization
**Action**:
- Group related functionality into clearly named directories
- Follow consistent naming conventions
- Reduce file sizes (target < 500 lines per file)
**Impact**: Easier for AI to understand context and make targeted changes.
**Priority**: HIGH

### 2. Add Type Aliases and Documentation
**Action**:
- Use descriptive type aliases for complex types
- Document units (degrees, radians, seconds, etc.)
- Add precondition/postcondition comments
**Impact**: Reduces ambiguity for AI code understanding.
**Priority**: MEDIUM

### 3. Reduce Nesting Depth
**Location**: `StateMachine.swift` - Several methods exceed 4 levels of nesting
**Action**: Extract nested logic into helper methods.
**Impact**: Easier for AI to parse and modify logic.
**Priority**: MEDIUM

### 4. Consistent Error Types
**Action**: 
- Create project-wide error enums
- Use structured error handling
- Avoid generic Error type
**Impact**: AI can better understand error cases and handling.
**Priority**: MEDIUM

### 5. Add Integration Examples
**Action**: Create example scripts showing:
- How to add a new AI integration
- How to add a new gesture
- How to modify tracking behavior
**Impact**: Provides templates for AI agents to follow.
**Priority**: HIGH

## 📊 Monitoring and Observability

### 1. Limited Telemetry
**Location**: `StateMachine.swift` uses custom telemetry logger
**Issue**: No structured logging framework.
**Action**: 
- Adopt OSLog or similar structured logging
- Add log levels (debug, info, warning, error)
- Create log aggregation strategy
**Priority**: MEDIUM

### 2. No Metrics Collection
**Issue**: No performance or usage metrics.
**Action**: Add metrics for:
- Response times from AI services
- Servo position accuracy
- Face detection success rate
**Priority**: LOW

### 3. No Health Checks
**Issue**: No way to monitor system health in production.
**Action**: Implement health check endpoints for critical services.
**Priority**: LOW

## 🔄 State Management Issues

### 1. Complex State Machine
**Location**: `StateMachine.swift` - 1493 lines
**Issue**: Single class handles too many responsibilities.
**Refactor**: Extract components:
- `TrackingController` - Face tracking logic
- `GestureController` - Hand gesture management
- `OrientationController` - Head/body positioning
- `ServoController` - Hardware interface
**Priority**: HIGH

### 2. Mutable State in Structs
**Location**: Multiple `mutating` functions in `BehaviorState`
**Issue**: Confusing mix of value and reference semantics.
**Refactor**: Consider making state classes or using proper state management pattern.
**Priority**: MEDIUM

## 🌐 Internationalization

### 1. Hardcoded Swedish Text
**Location**: `App.swift:24-31`, `PromptModels.swift` (throughout)
**Issue**: All prompts and text hardcoded in Swedish.
**Action**: 
- Extract strings to localization files
- Support multiple languages
- Make language selectable
**Priority**: LOW (unless internationalization is a goal)

## 📦 Dependency Management

### 1. Missing Package.swift
**Issue**: No Swift Package Manager manifest.
**Action**: Create Package.swift for dependency management.
**Priority**: MEDIUM

### 2. Python Dependencies Not Documented
**Issue**: No requirements.txt for Python TTS server.
**Action**: Create requirements.txt with pinned versions.
**Priority**: HIGH

### 3. Unclear Phidget Dependencies
**Issue**: Large auto-generated Phidget files without source tracking.
**Action**: Document Phidget library version and source.
**Priority**: MEDIUM

## 🎨 Code Style Consistency

### 1. Inconsistent Naming
**Issue**: Mix of camelCase and snake_case in struct properties.
**Example**: `correct_answer` vs `helloPhrase`
**Action**: Standardize on Swift conventions (camelCase).
**Priority**: LOW

### 2. Missing SwiftLint Configuration
**Issue**: No automated style enforcement.
**Action**: Add .swiftlint.yml with project standards.
**Priority**: LOW

## Summary

**Critical Items** (Do First):
1. Fix force unwrapping and hardcoded paths
2. Refactor OpenAI/Koala duplication
3. Split App.swift into logical components
4. Add basic unit tests
5. Create hardware abstraction layer
6. Document Python dependencies

**High Priority** (Do Soon):
1. Remove commented-out code
2. Add comprehensive API documentation
3. Implement proper configuration management
4. Improve code organization for AI agents

**Medium Priority** (Plan For):
1. Consistent error handling
2. Improve state management architecture
3. Add integration tests
4. Set up CI/CD

**Low Priority** (Nice to Have):
1. Performance optimizations
2. Internationalization support
3. Code style enforcement
4. Metrics and monitoring
