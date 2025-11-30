// SpeechQueueConfiguration.swift
// Configuration for the filesystem-based speech queue system.

import Foundation

/// Configuration for the filesystem-based speech queue.
/// This struct defines paths and limits for the conversation set queue.
struct SpeechQueueConfiguration: Equatable, Sendable {
    /// Directory where pending conversation sets are stored.
    let queueDirectory: URL
    
    /// Directory where completed conversation sets are moved.
    let doneDirectory: URL
    
    /// Maximum number of sets before pausing generation.
    /// When queue reaches this size, SantaSpeaker will wait before generating more.
    let maxQueueSize: Int
    
    /// Minimum number of sets before resuming generation.
    /// When queue falls below this, SantaSpeaker will start generating again.
    let minQueueSize: Int
    
    /// Delay in seconds between conversation set generations.
    let generationThrottleSeconds: Int
    
    /// Delay in seconds between queue-size checks while generation is paused.
    let queueFullCheckIntervalSeconds: Int
    
    /// Maximum number of completed sets to keep in DONE folder.
    /// Older sets beyond this limit will be pruned.
    let maxDoneSetsToKeep: Int
    
    /// Default configuration using ~/RoboSanta/SpeechQueue paths.
    static let `default` = SpeechQueueConfiguration(
        queueDirectory: URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("RoboSanta/SpeechQueue"),
        doneDirectory: URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("RoboSanta/SpeechQueue/DONE"),
        maxQueueSize: 500,
        minQueueSize: 5,
        generationThrottleSeconds: 0,
        queueFullCheckIntervalSeconds: 5,
        maxDoneSetsToKeep: 50
    )
    
    /// Creates configuration with custom paths.
    /// - Parameters:
    ///   - queueDirectory: Directory for pending sets
    ///   - doneDirectory: Directory for completed sets (should be inside queueDirectory)
    ///   - maxQueueSize: Maximum queue size before pausing generation
    ///   - minQueueSize: Minimum queue size before resuming generation
    ///   - generationThrottleSeconds: Delay between generations
    ///   - queueFullCheckIntervalSeconds: Delay between queue checks while paused
    ///   - maxDoneSetsToKeep: Maximum completed sets to retain
    init(
        queueDirectory: URL,
        doneDirectory: URL,
        maxQueueSize: Int = 500,
        minQueueSize: Int = 5,
        generationThrottleSeconds: Int = 0,
        queueFullCheckIntervalSeconds: Int = 5,
        maxDoneSetsToKeep: Int = 50
    ) {
        self.queueDirectory = queueDirectory
        self.doneDirectory = doneDirectory
        self.maxQueueSize = maxQueueSize
        self.minQueueSize = minQueueSize
        self.generationThrottleSeconds = generationThrottleSeconds
        self.queueFullCheckIntervalSeconds = queueFullCheckIntervalSeconds
        self.maxDoneSetsToKeep = maxDoneSetsToKeep
    }
}
