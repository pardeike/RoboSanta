// InteractionCoordinator.swift
// Coordinates speech playback with person detection and StateMachine control.

import Foundation
import Combine
import Observation

/// Coordinates between SantaSpeaker (background generation), StateMachine (animations),
/// and AudioPlayer (speech playback) to create interactive Santa conversations.
@Observable
@MainActor
final class InteractionCoordinator {
    
    // MARK: - Public State
    
    /// Current interaction state
    private(set) var state: InteractionState = .idle
    
    /// Whether audio is currently playing
    private(set) var isSpeaking: Bool = false
    
    /// Number of conversation sets in queue
    private(set) var queueCount: Int = 0
    
    /// Current conversation set being played (if any)
    private(set) var currentSetId: String? = nil
    
    // MARK: - Dependencies
    
    private let stateMachine: StateMachine
    private let audioPlayer: AudioPlayer
    private let queueManager: SpeechQueueManager
    private let config: InteractionConfiguration
    
    // MARK: - Detection State
    
    private var personTracked: Bool = false
    private var faceYawAngle: Double? = nil
    private var lastDetectionTime: Date? = nil
    private var trackingStartTime: Date? = nil
    
    // MARK: - Current Conversation
    
    private var currentSet: ConversationSet? = nil
    private var currentPhraseIndex: Int = 0
    private var lastLookingTime: Date? = nil
    
    // MARK: - Combine
    
    private var cancellables = Set<AnyCancellable>()
    private var loopTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates an InteractionCoordinator with the specified dependencies.
    /// - Parameters:
    ///   - stateMachine: The StateMachine controlling Santa's animations
    ///   - audioPlayer: The AudioPlayer for speech playback
    ///   - queueManager: The SpeechQueueManager for conversation sets
    ///   - config: Configuration for interaction thresholds
    init(
        stateMachine: StateMachine,
        audioPlayer: AudioPlayer,
        queueManager: SpeechQueueManager,
        config: InteractionConfiguration = .default
    ) {
        self.stateMachine = stateMachine
        self.audioPlayer = audioPlayer
        self.queueManager = queueManager
        self.config = config
        
        setupSubscriptions()
    }
    
    deinit {
        loopTask?.cancel()
    }
    
    // MARK: - Lifecycle
    
    /// Starts the interaction coordinator.
    /// Call this after StateMachine and SantaSpeaker are started.
    func start() {
        print("🎄 InteractionCoordinator: Starting")
        
        // Clean up any orphaned in-progress sets from previous runs
        queueManager.cleanupOrphanedInProgress()
        
        // Initial queue scan
        updateQueueState()
        
        // Start the main coordination loop
        loopTask = Task { await runCoordinationLoop() }
    }
    
    /// Stops the interaction coordinator.
    func stop() {
        print("🎄 InteractionCoordinator: Stopping")
        loopTask?.cancel()
        loopTask = nil
        
        // Stop any ongoing playback
        audioPlayer.stop()
        
        // Release current set if any
        if let set = currentSet {
            queueManager.releaseCurrentSet(set)
            currentSet = nil
        }
        
        state = .idle
    }
    
    // MARK: - Private Setup
    
    private func setupSubscriptions() {
        // Subscribe to detection updates from StateMachine
        stateMachine.detectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDetectionUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Detection Handling
    
    private func handleDetectionUpdate(_ update: StateMachine.DetectionUpdate) {
        let previouslyTracked = personTracked
        
        personTracked = update.personDetected
        faceYawAngle = update.faceYaw
        
        if update.personDetected {
            lastDetectionTime = update.timestamp
            if trackingStartTime == nil {
                trackingStartTime = update.timestamp
            }
            
            // Track when person was last looking at Santa
            if isPersonLooking() {
                lastLookingTime = update.timestamp
            }
        } else {
            trackingStartTime = nil
        }
        
        // Handle person lost during interaction
        if previouslyTracked && !personTracked && state.isSpeaking {
            handlePersonLostDuringSpeech()
        }
        
        print("🎄 Detection: tracked=\(personTracked), yaw=\(faceYawAngle ?? 0), state=\(state)")
    }
    
    // MARK: - Engagement Detection
    
    /// Returns true if person is looking at Santa (face yaw within tolerance)
    func isPersonLooking() -> Bool {
        guard let yaw = faceYawAngle else { return false }
        return abs(yaw) <= config.faceYawToleranceDeg
    }
    
    /// Returns true if person has been tracked long enough to engage
    func hasTrackedLongEnough() -> Bool {
        guard let start = trackingStartTime else { return false }
        return Date().timeIntervalSince(start) >= config.personDetectionDurationSeconds
    }
    
    /// Returns true if person is engaged (looking + tracked long enough)
    func isPersonEngaged() -> Bool {
        return personTracked && isPersonLooking() && hasTrackedLongEnough()
    }
    
    // MARK: - Queue Management
    
    private func updateQueueState() {
        queueManager.scanQueue()
        queueCount = queueManager.queueCount
    }
    
    private func updateIdleBehavior() {
        if queueManager.hasContent {
            stateMachine.send(.setIdleBehavior(.defaultPatrolBehavior))
        } else {
            stateMachine.send(.setIdleBehavior(.defaultMinimalIdleBehavior))
        }
    }
    
    // MARK: - Coordination Loop
    
    private func runCoordinationLoop() async {
        while !Task.isCancelled {
            await coordinationTick()
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms - sufficient for state changes
        }
    }
    
    private func coordinationTick() async {
        // Update queue state periodically
        updateQueueState()
        
        switch state {
        case .idle:
            await handleIdleState()
            
        case .patrolling:
            await handlePatrollingState()
            
        case .personDetected:
            await handlePersonDetectedState()
            
        case .greeting:
            // Greeting is handled by playback task
            break
            
        case .conversing:
            // Conversing is handled by playback task
            break
            
        case .farewell:
            // Farewell is handled by playback task
            break
            
        case .personLost:
            await handlePersonLostState()
        }
    }
    
    // MARK: - State Handlers
    
    private func handleIdleState() async {
        if queueManager.hasContent {
            print("🎄 Queue has content, transitioning to patrolling")
            state = .patrolling
            updateIdleBehavior()
        }
    }
    
    private func handlePatrollingState() async {
        // Check if queue is empty
        if !queueManager.hasContent {
            print("🎄 Queue empty, transitioning to idle")
            state = .idle
            updateIdleBehavior()
            return
        }
        
        // Check for engaged person
        if isPersonEngaged() {
            print("🎄 Person engaged, transitioning to personDetected")
            state = .personDetected
        }
    }
    
    private func handlePersonDetectedState() async {
        // Verify person is still engaged
        guard isPersonEngaged() else {
            print("🎄 Person no longer engaged, returning to patrolling")
            state = .patrolling
            return
        }
        
        // Check if queue has content
        guard queueManager.hasContent else {
            print("🎄 Queue empty during personDetected, returning to idle")
            state = .idle
            updateIdleBehavior()
            return
        }
        
        // Start conversation
        await startConversation()
    }
    
    private func handlePersonLostState() async {
        // Clean up and return to appropriate state
        if let set = currentSet {
            queueManager.moveToCompleted(set)
            currentSet = nil
        }
        
        currentSetId = nil
        isSpeaking = false
        
        if queueManager.hasContent {
            state = .patrolling
        } else {
            state = .idle
        }
        
        updateIdleBehavior()
    }
    
    private func handlePersonLostDuringSpeech() {
        print("🎄 Person lost during speech")
        
        // Check if we should play farewell
        let shouldPlayFarewell: Bool
        if let lastDetection = lastDetectionTime {
            shouldPlayFarewell = Date().timeIntervalSince(lastDetection) < config.farewellSkipThresholdSeconds
        } else {
            shouldPlayFarewell = false
        }
        
        if shouldPlayFarewell && state != .farewell {
            // Transition to farewell (will play end.wav)
            state = .farewell
            Task { await playFarewell() }
        } else {
            // Skip farewell, go directly to personLost
            audioPlayer.stop()
            state = .personLost
        }
    }
    
    // MARK: - Conversation Playback
    
    private func startConversation() async {
        // Consume a conversation set
        guard let set = queueManager.consumeOldest() else {
            print("🎄 Failed to consume conversation set")
            state = .patrolling
            return
        }
        
        currentSet = set
        currentSetId = set.id
        currentPhraseIndex = 0
        lastLookingTime = Date()
        
        print("🎄 Starting conversation with set: \(set.id)")
        
        // Start with greeting
        state = .greeting
        isSpeaking = true
        
        // Play start phrase
        let startSuccess = await audioPlayer.playStart(of: set)
        
        guard startSuccess && !Task.isCancelled else {
            print("🎄 Start phrase failed or cancelled")
            await cleanupConversation()
            return
        }
        
        // Check if person is still engaged after start
        if !personTracked {
            print("🎄 Person lost after greeting")
            state = .personLost
            await cleanupConversation()
            return
        }
        
        // Play middle phrases if any
        if !set.middleFiles.isEmpty {
            await playMiddlePhrases(set: set)
        }
        
        // Play farewell if person is still around
        if personTracked || isRecentlyLost() {
            await playFarewell()
        }
        
        await cleanupConversation()
    }
    
    private func playMiddlePhrases(set: ConversationSet) async {
        for (index, middleFile) in set.middleFiles.enumerated() {
            currentPhraseIndex = index + 1
            state = .conversing(phraseIndex: index + 1, totalPhrases: set.middleFiles.count)
            
            // Check if person is still looking before each phrase
            if !isPersonLooking() && !hasRecentlyLooked() {
                print("🎄 Person stopped looking, skipping remaining middle phrases")
                break
            }
            
            // Check if person is lost
            if !personTracked {
                print("🎄 Person lost during middle phrases")
                break
            }
            
            // Play the phrase
            let success = await audioPlayer.play(middleFile)
            
            guard success && !Task.isCancelled else {
                print("🎄 Middle phrase \(index + 1) failed or cancelled")
                break
            }
        }
    }
    
    private func playFarewell() async {
        guard let set = currentSet else { return }
        
        state = .farewell
        
        let success = await audioPlayer.playEnd(of: set)
        
        if success {
            print("🎄 Farewell completed")
        } else {
            print("🎄 Farewell failed or cancelled")
        }
    }
    
    private func cleanupConversation() async {
        if let set = currentSet {
            queueManager.moveToCompleted(set)
            print("🎄 Moved set \(set.id) to completed")
        }
        
        currentSet = nil
        currentSetId = nil
        currentPhraseIndex = 0
        isSpeaking = false
        
        // Return to appropriate state
        updateQueueState()
        if queueManager.hasContent {
            state = .patrolling
        } else {
            state = .idle
        }
        
        updateIdleBehavior()
    }
    
    // MARK: - Helpers
    
    /// Returns true if person was recently looking (within timeout)
    private func hasRecentlyLooked() -> Bool {
        guard let lastLook = lastLookingTime else { return false }
        return Date().timeIntervalSince(lastLook) < config.lookAwayTimeoutSeconds
    }
    
    /// Returns true if person was recently detected (within farewell threshold)
    private func isRecentlyLost() -> Bool {
        guard let lastDetection = lastDetectionTime else { return false }
        return Date().timeIntervalSince(lastDetection) < config.farewellSkipThresholdSeconds
    }
}
