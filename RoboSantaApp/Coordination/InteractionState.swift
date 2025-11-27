// InteractionState.swift
// States for the interaction coordinator state machine.

import Foundation

/// States for the InteractionCoordinator.
/// Manages the flow from idle to active conversation and back.
enum InteractionState: Equatable, Sendable, CustomStringConvertible {
    /// Queue empty, performing minimal idle animation
    case idle
    
    /// Queue has content, looking for people (patrol mode)
    case patrolling
    
    /// Person found, evaluating if they're engaged (checking face yaw)
    case personDetected
    
    /// Playing start.wav, monitoring if person is still looking
    case greeting
    
    /// Playing middle*.wav phrases, checking engagement between phrases
    case conversing(phraseIndex: Int, totalPhrases: Int)
    
    /// Playing end.wav (farewell)
    case farewell
    
    /// Person left, cleanup in progress
    case personLost
    
    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .patrolling:
            return "patrolling"
        case .personDetected:
            return "personDetected"
        case .greeting:
            return "greeting"
        case .conversing(let index, let total):
            return "conversing(\(index)/\(total))"
        case .farewell:
            return "farewell"
        case .personLost:
            return "personLost"
        }
    }
    
    /// Whether the state involves active speech playback
    var isSpeaking: Bool {
        switch self {
        case .greeting, .conversing, .farewell:
            return true
        default:
            return false
        }
    }
    
    /// Whether the state should respond to person detection events
    var respondsToDetection: Bool {
        switch self {
        case .idle, .patrolling, .personDetected:
            return true
        default:
            return false
        }
    }
}
