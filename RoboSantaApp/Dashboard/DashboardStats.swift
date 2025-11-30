// DashboardStats.swift
// Observable statistics model for the dashboard.

import Foundation
import Observation
import Combine

/// Tracks statistics about Santa's interactions for the dashboard display.
@Observable
@MainActor
final class DashboardStats {
    
    // MARK: - Interaction Counts
    
    /// Number of greeting interactions played
    private(set) var greetingCount: Int = 0
    
    /// Number of pepp talk interactions played
    private(set) var peppCount: Int = 0
    
    /// Number of quiz interactions played
    private(set) var quizCount: Int = 0
    
    /// Number of joke interactions played
    private(set) var jokeCount: Int = 0
    
    /// Number of pointing interactions played
    private(set) var pointingCount: Int = 0
    
    /// Total number of interactions played
    var totalInteractions: Int {
        greetingCount + peppCount + quizCount + jokeCount + pointingCount
    }
    
    // MARK: - Engagement Statistics
    
    /// People who walked by without engaging (detected but left quickly)
    private(set) var ignoredCount: Int = 0
    
    /// People who showed some interest but left during interaction
    private(set) var partialEngagementCount: Int = 0
    
    /// People who stayed for the full interaction
    private(set) var fullEngagementCount: Int = 0
    
    // MARK: - People Statistics
    
    /// Number of unique people detected (approximation based on sessions)
    private(set) var peopleEngaged: Int = 0
    
    /// Number of times people were detected
    private(set) var totalDetections: Int = 0
    
    // MARK: - Session Statistics
    
    /// Session start time
    let sessionStartTime: Date = Date()
    
    /// Duration the session has been running
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    /// Formatted session duration string
    var formattedDuration: String {
        let hours = Int(sessionDuration) / 3600
        let minutes = (Int(sessionDuration) % 3600) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Live State
    
    /// Current interaction state name
    private(set) var currentStateName: String = "idle"
    
    /// Current generation status
    private(set) var generationStatus: String = "Väntar..."
    
    /// Whether a person is currently detected
    private(set) var personDetected: Bool = false
    
    /// Current face yaw angle (if detected)
    private(set) var faceYaw: Double? = nil
    
    // MARK: - Subscriptions
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Shared Instance
    
    /// Shared instance for app-wide access
    static let shared = DashboardStats()
    
    private init() {}
    
    // MARK: - Recording Methods
    
    /// Records that an interaction was completed
    func recordInteraction(type: InteractionType) {
        switch type {
        case .greeting:
            greetingCount += 1
        case .pepp:
            peppCount += 1
        case .quiz:
            quizCount += 1
        case .joke:
            jokeCount += 1
        case .pointing:
            pointingCount += 1
        case .unknown:
            greetingCount += 1 // Count unknown as greeting
        }
    }
    
    /// Records engagement level when interaction ends
    /// - Parameter completed: true if person stayed for full interaction, false if they left early
    func recordEngagement(completed: Bool) {
        if completed {
            fullEngagementCount += 1
        } else {
            partialEngagementCount += 1
        }
    }
    
    /// Records that a person walked by without engaging
    func recordIgnored() {
        ignoredCount += 1
    }
    
    /// Records that a person was engaged
    func recordPersonEngaged() {
        peopleEngaged += 1
    }
    
    /// Records a person detection event
    func recordDetection() {
        totalDetections += 1
    }
    
    /// Updates the current interaction state
    func updateState(_ state: InteractionState) {
        currentStateName = state.description
    }
    
    /// Updates the generation status
    func updateGenerationStatus(_ status: String) {
        generationStatus = status
    }
    
    /// Updates person detection state
    func updateDetection(detected: Bool, yaw: Double?) {
        personDetected = detected
        faceYaw = yaw
    }
    
    // MARK: - Subscription Setup
    
    /// Connects to the state machine's detection publisher
    func connectToStateMachine(_ stateMachine: StateMachine) {
        stateMachine.detectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.updateDetection(detected: update.personDetected, yaw: update.faceYaw)
                if update.personDetected && (self?.personDetected == false) {
                    self?.recordDetection()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Connects to the interaction coordinator
    func connectToInteractionCoordinator(_ coordinator: InteractionCoordinator) {
        // Note: This would need to be called with observation or another mechanism
        // Since InteractionCoordinator uses @Observable, we can observe it directly
    }
}
