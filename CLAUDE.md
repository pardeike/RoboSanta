# Claude Agent Quick Reference

This document serves as the entry point for AI coding agents (like Claude) working on the RoboSanta codebase.

## 📚 Primary Documentation

**Start here**: [AGENTS.md](AGENTS.md)

AGENTS.md contains:
- Complete project context and architecture
- Code patterns and conventions
- Component responsibilities
- Common task templates
- Testing strategies
- Debugging tips
- CLI build and run commands
- Important warnings and best practices

## 🚧 Current Development

**Implementation Reference**: [IMPLEMENTATION.md](IMPLEMENTATION.md)

IMPLEMENTATION.md describes the current interactive RoboSanta system architecture:
- Filesystem-based speech queue system
- InteractionCoordinator orchestration
- Detection and engagement logic
- State machine coordination
- Configuration defaults and troubleshooting

## 🎯 Quick Start Checklist

Before making any changes:

1. ✅ Read [AGENTS.md](AGENTS.md) - understand the project structure
2. ✅ Check [IMPLEMENTATION.md](IMPLEMENTATION.md) - see if your task is part of the active refactoring
3. ✅ Review the specific files you'll be modifying
4. ✅ Understand the event-driven architecture (StateMachine uses events)
5. ✅ Follow async/await patterns throughout
6. ✅ Use the Settings structs for configuration (no hardcoded values)
7. ✅ Add comprehensive logging for new behaviors
8. ✅ Test changes incrementally

## 📁 Key Files

### Entry Points
- **App.swift** - Application entry and configuration
- **RuntimeCoordinator.swift** - Coordinates rig + detection source
- **SantaRig.swift** - High-level figurine control (Physical/Virtual)

### Core Components
- **StateMachine.swift** (~2000 lines) - Servo control and person tracking
- **SantaSpeaker.swift** - Speech generation with queue-based mode
- **InteractionCoordinator.swift** - Coordinates speech + detection + gestures
- **DetectionRouter.swift** - Routes detection to StateMachine

### Configuration
- **StateMachineSettings.swift** - All tunable parameters
- **InteractionConfiguration.swift** - Interaction thresholds
- **Tools.swift** - Helper protocols (Think, SantaVoice)

### Speech Queue
- **SpeechQueueManager.swift** - Filesystem queue management
- **ConversationSet.swift** - Conversation set validation

## ⚠️ Critical Warnings

1. **Never modify `Phidget22/` directory** - auto-generated bindings
2. **StateMachine.swift is complex** - ~2000 lines, be extremely careful
3. **Always use Settings structs** - no hardcoded values
4. **Respect async/await** - don't use completion handlers
5. **Thread safety matters** - StateMachine has dedicated queue
6. **Swedish language** - all prompts and content are in Swedish

## 🔨 Build & Run

From repo root with Xcode installed:

```bash
# Set Xcode path (or use sudo xcode-select)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Build
xcodebuild -scheme RoboSantaApp -project RoboSanta.xcodeproj \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build build

# Run (requires logged-in macOS session for camera/USB)
./build/Build/Products/Debug/RoboSanta.app/Contents/MacOS/RoboSanta
```

See AGENTS.md for async run with logging.

## 🤝 Getting Help

1. Check AGENTS.md for patterns and examples
2. Check IMPLEMENTATION.md for refactoring context
3. Review similar code in the codebase
4. Enable verbose logging to understand behavior
5. Test incrementally with small changes
6. Ask the human maintainer for hardware-specific questions

---

**Remember**: This is a physical hardware project. Incorrect servo commands could damage hardware or cause unexpected behavior. When in doubt, ask before making changes that affect servo movement.

Good luck! 🎅
