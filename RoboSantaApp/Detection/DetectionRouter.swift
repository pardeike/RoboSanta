// DetectionRouter.swift
// Routes detection frames to StateMachine events.
// Extracted from CameraManager.driveFigurine() for reuse with virtual detection.

import Foundation
import Combine

/// Routes detection frames to StateMachine events.
/// Extracted from CameraManager.driveFigurine() for reuse with virtual detection.
final class DetectionRouter {
    private let stateMachine: StateMachine
    private let lostThreshold: TimeInterval
    private var hasActiveFace = false
    private var lastFaceTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init(stateMachine: StateMachine, lostThreshold: TimeInterval = 0.6) {
        self.stateMachine = stateMachine
        self.lostThreshold = lostThreshold
    }
    
    func connect(to source: PersonDetectionSource) {
        source.detectionFrames
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.handleDetectionFrame(frame)
            }
            .store(in: &cancellables)
    }
    
    func disconnect() {
        cancellables.removeAll()
        hasActiveFace = false
        lastFaceTimestamp = nil
    }
    
    private func handleDetectionFrame(_ frame: DetectionFrame) {
        let width = frame.size.width
        guard width > 0 else { return }
        
        // Find the face closest to center (matches CameraManager logic)
        if let candidate = frame.faces.min(by: { abs($0.relativeOffset) < abs($1.relativeOffset) }) {
            hasActiveFace = true
            lastFaceTimestamp = Date()
            stateMachine.send(.personDetected(relativeOffset: candidate.relativeOffset))
        } else {
            guard hasActiveFace else { return }
            if let last = lastFaceTimestamp, Date().timeIntervalSince(last) < lostThreshold { return }
            hasActiveFace = false
            lastFaceTimestamp = nil
            stateMachine.send(.personLost)
        }
    }
}
