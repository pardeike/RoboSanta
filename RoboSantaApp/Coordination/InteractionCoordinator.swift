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
    private var lastLoggedQueueCount: Int? = nil
    private var pendingLossAfterCurrentPhrase: Bool = false
    
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
        config: InteractionConfiguration
    ) {
        self.stateMachine = stateMachine
        self.audioPlayer = audioPlayer
        self.queueManager = queueManager
        self.config = config
        
        setupSubscriptions()
    }
    
    isolated deinit {
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
        
        // Sync StateMachine idle behavior with current queue state
        // This ensures we start in minimal idle mode when queue is empty,
        // rather than defaulting to patrol mode
        updateIdleBehavior()
        
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
            pendingLossAfterCurrentPhrase = false
        }
        
        if update.personDetected {
            lastDetectionTime = update.timestamp
            if trackingStartTime == nil {
                trackingStartTime = update.timestamp
            }
            
            // Track when person was last looking at Santa
            if isPersonLooking(tolerance: config.postGreetingFaceYawToleranceDeg) {
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
    func isPersonLooking(tolerance: Double? = nil) -> Bool {
        guard let yaw = faceYawAngle else { return false }
        let limit = tolerance ?? config.faceYawToleranceDeg
        return abs(yaw) <= limit
    }
    
    /// Returns true if person has been tracked long enough to engage
    func hasTrackedLongEnough() -> Bool {
        guard let start = trackingStartTime else { return false }
        return Date().timeIntervalSince(start) >= config.personDetectionDurationSeconds
    }
    
    /// Returns true if a person is tracked long enough regardless of face angle (used to start greeting).
    func isPersonPresentForGreeting() -> Bool {
        return personTracked && hasTrackedLongEnough()
    }
    
    /// Returns true if person is engaged (looking + tracked long enough)
    func isPersonEngaged() -> Bool {
        return personTracked && isPersonLooking() && hasTrackedLongEnough()
    }
    
    // MARK: - Queue Management
    
    private func updateQueueState() {
        queueManager.scanQueue()
        let newCount = queueManager.queueCount
        queueCount = newCount
        
        if lastLoggedQueueCount != newCount {
            lastLoggedQueueCount = newCount
            print("📊 Interaction: Queue has \(newCount) set(s)")
        }
    }
    
    private func updateIdleBehavior() {
        if queueManager.hasContent {
            print("🌲 Interaction: Setting patrol idle behavior (queue has content)")
            stateMachine.send(.setIdleBehavior(.defaultPatrolBehavior))
        } else {
            print("🌲 Interaction: Setting minimal idle behavior (queue empty)")
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
            transition(to: .patrolling, reason: "queue has content")
            updateIdleBehavior()
        }
    }
    
    private func handlePatrollingState() async {
        // Check if queue is empty
        if !queueManager.hasContent {
            transition(to: .idle, reason: "queue empty")
            updateIdleBehavior()
            return
        }
        
        // Check for engaged person
        if isPersonPresentForGreeting() {
            transition(to: .personDetected, reason: "person detected (pre-greeting)")
        }
    }
    
    private func handlePersonDetectedState() async {
        // Verify person is still engaged
        guard isPersonPresentForGreeting() else {
            transition(to: .patrolling, reason: "person no longer detected for greeting")
            return
        }
        
        // Check if queue has content
        guard queueManager.hasContent else {
            print("🎄 Queue empty during personDetected, returning to idle")
            transition(to: .idle, reason: "queue empty")
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
            transition(to: .patrolling, reason: "cleanup complete, queue has content")
        } else {
            transition(to: .idle, reason: "cleanup complete, queue empty")
        }
        
        updateIdleBehavior()
    }
    
    private func handlePersonLostDuringSpeech() {
        print("🎄 Person lost during speech")
        
        // Allow the current phrase to finish, then bail.
        if audioPlayer.isPlaying && !pendingLossAfterCurrentPhrase {
            pendingLossAfterCurrentPhrase = true
            print("⏳ Will stop after current phrase finishes")
            return
        }
        
        // Check if we should play farewell
        let shouldPlayFarewell: Bool
        if let lastDetection = lastDetectionTime {
            shouldPlayFarewell = Date().timeIntervalSince(lastDetection) < config.farewellSkipThresholdSeconds
        } else {
            shouldPlayFarewell = false
        }
        
        if shouldPlayFarewell && state != .farewell {
            // Transition to farewell (will play end.wav)
            transition(to: .farewell, reason: "person lost recently")
            Task { await playFarewell() }
        } else {
            // Skip farewell, go directly to personLost
            audioPlayer.stop()
            transition(to: .personLost, reason: "person lost, skipping farewell")
        }
    }
    
    // MARK: - Conversation Playback
    
    private func startConversation() async {
        // Consume a conversation set
        guard let set = queueManager.consumeOldest() else {
            print("🎄 Failed to consume conversation set")
            transition(to: .patrolling, reason: "no set to consume")
            return
        }
        
        currentSet = set
        currentSetId = set.id
        currentPhraseIndex = 0
        lastLookingTime = nil
        
        print("🎄 Starting conversation with set: \(set.id) [type: \(set.type)]")
        
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
            _ = await audioPlayer.playStart(of: set)
            // Pepp has no farewell
            await cleanupConversation()
            return
            
        default:
            // Standard flow for greeting, quiz, joke, unknown
            break
        }
        
        // Start with greeting
        transition(to: .greeting, reason: "starting conversation")
        isSpeaking = true
        
        // Play start phrase
        let startSuccess = await audioPlayer.playStart(of: set)
        
        guard startSuccess && !Task.isCancelled else {
            print("🎄 Start phrase failed or cancelled")
            await cleanupConversation()
            return
        }
        
        print("👀 Post-greeting check: tracked=\(personTracked) yaw=\(faceYawAngle.map { String(format: "%.1f", $0) } ?? "nil") lastLook=\(lastLookingTime?.timeIntervalSinceNow ?? 0)")
        
        // Record a recent look if they're facing us now with lenient tolerance.
        if personTracked && isPersonLooking(tolerance: config.postGreetingFaceYawToleranceDeg) {
            lastLookingTime = Date()
        }
        
        // Check engagement after the greeting to decide whether to continue.
        let attentive = personTracked && (isPersonLooking(tolerance: config.postGreetingFaceYawToleranceDeg) || hasRecentlyLooked())
        let yawDesc = faceYawAngle.map { String(format: "%.1f", $0) } ?? "nil"
        print("🎯 Post-greeting engagement: tracked=\(personTracked) yaw=\(yawDesc) tol=\(config.postGreetingFaceYawToleranceDeg) recentLook=\(hasRecentlyLooked())")
        if !attentive {
            print("🎄 Person not engaged after greeting; skipping conversation")
            await playFarewell()
            await cleanupConversation()
            return
        }
        
        if pendingLossAfterCurrentPhrase {
            print("🚪 Person already lost during greeting; ending conversation after greeting")
            pendingLossAfterCurrentPhrase = false
            await cleanupConversation()
            return
        }
        
        // Play middle phrases if any
        if !set.middleFiles.isEmpty {
            let shouldContinue = await playMiddlePhrases(set: set)
            if !shouldContinue {
                await cleanupConversation()
                return
            }
        }
        
        // Play farewell if person is still around AND set has an end
        if (personTracked || isRecentlyLost()) && set.hasEnd {
            await playFarewell()
        }
        
        await cleanupConversation()
    }
    
    /// Plays a pointing interaction with synchronized arm gestures.
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
    
    private func playMiddlePhrases(set: ConversationSet) async -> Bool {
        for (index, middleFile) in set.middleFiles.enumerated() {
            currentPhraseIndex = index + 1
            transition(to: .conversing(phraseIndex: index + 1, totalPhrases: set.middleFiles.count), reason: "playing middle phrase \(index + 1)")
            
            // Check if person is still looking before each phrase
            if !isPersonLooking(tolerance: config.postGreetingFaceYawToleranceDeg) && !hasRecentlyLooked() {
                let yawDesc = faceYawAngle.map { String(format: "%.1f", $0) } ?? "nil"
                print("🎄 Person stopped looking (yaw=\(yawDesc), tol=\(config.postGreetingFaceYawToleranceDeg)), skipping remaining middle phrases")
                return false
            }
            
            // Check if person is lost
            if !personTracked {
                print("🎄 Person lost during middle phrases")
                return false
            }
            
            // Play the phrase
            let success = await audioPlayer.play(middleFile)
            
            guard success && !Task.isCancelled else {
                print("🎄 Middle phrase \(index + 1) failed or cancelled")
                return false
            }
            
            if pendingLossAfterCurrentPhrase {
                print("🚪 Person lost during phrase; stopping after this phrase")
                pendingLossAfterCurrentPhrase = false
                return false
            }
        }
        
        return true
    }
    
    private func playFarewell() async {
        guard let set = currentSet else { return }
        
        transition(to: .farewell, reason: "playing farewell")
        
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
            transition(to: .patrolling, reason: "conversation complete, queue has content")
        } else {
            transition(to: .idle, reason: "conversation complete, queue empty")
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
    
    /// Logs state transitions with reason.
    private func transition(to newState: InteractionState, reason: String) {
        guard state != newState else { return }
        print("🎛 Interaction: \(state) -> \(newState) (\(reason))")
        state = newState
    }
}
