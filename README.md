# 🎅 RoboSanta - Interactive Santa Claus Animatronics

An interactive Santa Claus animatronic figurine that uses AI to engage with people passing by in an office corridor. Built with Swift 6 and powered by computer vision, text-to-speech, and servo-controlled movement.

## 🎯 Project Purpose

RoboSanta is designed to entertain and delight people as they walk through office corridors. The animatronic Santa:
- Detects people using computer vision
- Tracks faces and follows movement with head and body servos
- Generates contextual Swedish greetings and conversations using AI
- Speaks using text-to-speech (TTS) with a Swedish voice
- Performs gestures like waving and pointing
- Creates an engaging, interactive experience

## 🛠️ Technology Stack

- **Language**: Swift 6
- **Platform**: macOS
- **Hardware**: 
  - Phidget RC servos (4 channels: head, body, left hand, right hand)
  - Camera for face detection (AVFoundation)
- **Computer Vision**: Apple Vision framework for face detection and tracking
- **AI/LLM Integration**:
  - Apple Intelligence (FoundationModels)
  - OpenAI-compatible APIs (Koala, custom endpoints)
  - Ollama for local LLM
- **Text-to-Speech**: 
  - Custom Python TTS server using Chatterbox multilingual TTS
  - ElevenLabs API support
- **Audio**: AVFoundation for audio playback

## 🏗️ Architecture Overview

### Core Components

```
RoboSantaApp/
├── App.swift                    # Main entry point and content generation
├── CameraManager.swift          # Face detection and tracking
├── Tools.swift                  # Utility functions and protocols
├── Figurine/                    # Physical figurine control
│   ├── StateMachine.swift       # Main control logic for servos
│   ├── StateMachineSettings.swift # Configuration parameters
│   ├── TelemetryLogger.swift    # Logging and diagnostics
│   ├── Handlers.swift           # Phidget event handlers
│   └── Functions.swift          # Servo control functions
├── Integrations/                # External service integrations
│   ├── AppleIntelligence.swift  # Apple's on-device AI
│   ├── OpenAI.swift             # OpenAI-compatible API client
│   ├── Koala.swift              # Koala API integration
│   ├── OllamaThink.swift        # Local Ollama integration
│   ├── ElevenLabs.swift         # ElevenLabs TTS
│   ├── RoboSantaTTS.swift       # Custom TTS integration
│   ├── TTSServer.swift          # Python TTS server manager
│   ├── Shared.swift             # Common interfaces (Think, SantaVoice)
│   └── PromptModels.swift       # Prompt templates and schemas
├── Phidget22/                   # Phidget hardware interfaces
└── tts-server.py                # Python TTS server
```

### Key Design Patterns

1. **Protocol-Oriented Design**:
   - `Think` protocol for AI text generation
   - `SantaVoice` protocol for text-to-speech
   - Enables easy swapping of implementations

2. **State Machine Pattern**: 
   - `StateMachine` coordinates servo movements
   - Handles tracking, idle behaviors, and gestures

3. **Event-Driven Architecture**:
   - Events trigger state changes (person detected/lost, gesture commands)
   - Async processing with Swift concurrency

## 🚀 Setup and Installation

### Prerequisites

1. **macOS** with Xcode installed
2. **Swift 6** toolchain
3. **Python 3.11** (via Homebrew):
   ```bash
   brew install python@3.11
   ```
4. **Phidget Hardware**:
   - 4x RC servo motors
   - Phidget servo controller
   - USB connection to Mac

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/pardeike/RoboSanta.git
   cd RoboSanta
   ```

2. **Install Python Dependencies**:
   ```bash
   cd RoboSantaApp
   pip3.11 install torch torchaudio transformers diffusers chatterbox
   ```

3. **Configure API Keys** (Optional):
   
   For ElevenLabs TTS:
   - Store API key in macOS Keychain with label "Elevenlabs API Key"
   
   For OpenAI-compatible services:
   - Configure in `App.swift` or use environment variables

4. **Open in Xcode**:
   ```bash
   open RoboSanta.xcodeproj
   ```

5. **Build and Run**:
   - Select the appropriate scheme
   - Build with ⌘+B
   - Run with ⌘+R

### Hardware Setup

1. Connect Phidget servo controller via USB
2. Connect 4 servos to channels:
   - Channel 0: Head rotation
   - Channel 1: Body rotation
   - Channel 2: Left hand
   - Channel 3: Right hand
3. Ensure servos are powered and within operating ranges

### Camera Setup

- Connect a webcam (prefers device named "Webcam")
- Grant camera permissions when prompted
- Adjust camera angle to capture passing people at eye level

## 📖 Usage

### Running the Animatronics

Simply build and run the project. The system will:

1. **Initialize Hardware**: Connect to Phidget servos
2. **Start TTS Server**: Launch Python TTS server in background
3. **Activate Camera**: Begin face detection
4. **Enter Idle Mode**: Start patrol behavior, scanning the area
5. **Detect and Track**: When a person is detected:
   - Track their face with head and body movement
   - After threshold time, raise hand and wave
   - Continue tracking as they move
6. **Return to Idle**: Resume patrol when person leaves

### Configuring AI Behavior

Edit `App.swift` to choose AI integration:

```swift
// Choose one:
static let thinker: Think = AppleIntelligence()
// static let thinker: Think = Koala()
// static let thinker: Think = OllamaThink(modelName: "qwen3:8b")
```

### Configuring TTS

Edit `App.swift` to choose TTS method:

```swift
static let voice: SantaVoice = RoboSantaTTS()
// static let voice: SantaVoice = ElevenLabs()
```

### Adjusting Servo Behavior

Modify settings in `StateMachineSettings.swift`:
- Tracking sensitivity
- Wave gesture parameters
- Movement speeds
- Patrol patterns

## 🎭 Interaction Modes

RoboSanta generates several types of interactions:

1. **Pepp Talk**: Uplifting, encouraging phrases
2. **Greeting**: Quick hello, conversation starter, goodbye
3. **Quiz**: Short trivia question with three choices
4. **Joke**: Playful secret and compliment

Each uses AI to generate contextually relevant Swedish text based on random topics.

## 🔧 Configuration

### StateMachine Settings

Key parameters in `StateMachineSettings.swift`:

- `loggingEnabled`: Enable/disable console logging
- `centerHoldOffsetNorm`: Deadzone for body movement (0.04-0.12)
- `headRateCapDegPerSec`: Maximum head rotation speed
- `bodyRateCapDegPerSec`: Maximum body rotation speed
- `leftHandWaveCycles`: Number of wave cycles (1-5)
- `leftHandCooldownDuration`: Time between waves

### Prompt Templates

Customize in `App.swift`:
- `baseSystem`: Core AI instructions (Swedish language, style)
- `passByTemplate`: Quick corridor greetings
- `peppTemplate`: Encouraging messages
- `quizTemplate`: Trivia questions
- `jokeTemplate`: Playful jokes

## 🐛 Troubleshooting

### TTS Server Won't Start

- Check Python 3.11 is installed: `which python3.11`
- Verify path in `TTSServer.swift` matches your installation
- Check Python dependencies are installed
- Look for errors in console output

### Servos Not Moving

- Verify Phidget hardware is connected (USB)
- Check servo power supply
- Ensure channels match physical connections
- Review console for attachment errors

### Face Detection Not Working

- Grant camera permissions
- Check camera is connected and recognized
- Verify camera angle covers target area
- Review console for Vision framework errors

### AI Generation Failures

- Check API keys are configured
- Verify network connectivity for cloud services
- Try switching to AppleIntelligence (on-device)
- Check console for API error messages

## 📊 Telemetry and Logging

The system logs to:
- **Console**: Real-time events and state changes
- **JSON File**: `telemetry.json` (gitignored) for detailed analysis

Enable logging in `StateMachineSettings.swift`:
```swift
let loggingEnabled = true
```

## 🧪 Development

### Adding a New AI Integration

1. Create new file implementing `Think` protocol:
   ```swift
   @MainActor
   struct MyAI: Think {
       func generate<T: Decodable>(...) async throws -> T {
           // Implementation
       }
   }
   ```

2. Update `App.swift`:
   ```swift
   static let thinker: Think = MyAI()
   ```

### Adding a New Gesture

1. Add to `StateMachine.LeftHandGesture` or `RightHandGesture`
2. Implement logic in `leftHandValue()` or `rightHandValue()`
3. Send event: `santa.send(.setLeftHand(.myNewGesture))`

### Adding a New Interaction Mode

1. Define schema in `PromptModels.swift`
2. Add template in `App.swift`
3. Add case to background loop in `App.swift`

## 📝 Contributing

When contributing to RoboSanta:

1. Follow Swift naming conventions
2. Add documentation for public interfaces
3. Test with hardware if possible
4. Update this README for significant changes
5. Check TODO.md for priority items

## 📄 License

Copyright © Andreas Pardeike

## 🙏 Acknowledgments

- Phidget for servo control hardware and SDK
- Apple for Vision framework and FoundationModels
- Chatterbox for multilingual TTS
- Various open-source Swift and Python libraries

## 📧 Contact

For questions or issues, please create an issue on GitHub or contact the maintainer.

---

**Note**: This is a work-in-progress project. See TODO.md for known issues and planned improvements.
