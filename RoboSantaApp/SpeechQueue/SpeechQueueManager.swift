// SpeechQueueManager.swift
// Manages the filesystem-based queue of conversation sets.

import Foundation
import Observation

/// Error types for speech queue operations.
enum SpeechQueueError: Error, LocalizedError {
    case directoryCreationFailed(URL)
    case setNotFound(String)
    case moveOperationFailed(URL, URL)
    case invalidSetStructure(URL)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let url):
            return "Failed to create directory at \(url.path)"
        case .setNotFound(let id):
            return "Conversation set not found: \(id)"
        case .moveOperationFailed(let source, let destination):
            return "Failed to move from \(source.path) to \(destination.path)"
        case .invalidSetStructure(let url):
            return "Invalid conversation set structure at \(url.path)"
        }
    }
}

/// Manages the filesystem-based queue of conversation sets.
/// Responsible for scanning, consuming, and moving conversation sets.
@Observable
final class SpeechQueueManager: @unchecked Sendable {
    
    /// Configuration for the queue
    let config: SpeechQueueConfiguration
    
    /// Currently available conversation sets (sorted oldest first)
    private(set) var availableSets: [ConversationSet] = []
    
    /// The set currently being consumed (marked as in-progress)
    private(set) var currentSet: ConversationSet?
    
    /// Whether the queue is currently being scanned
    private(set) var isScanning = false
    
    /// Number of available sets
    var queueCount: Int { availableSets.count }
    
    /// Whether the queue has content available
    var hasContent: Bool { !availableSets.isEmpty }
    
    /// Whether generation should be paused (queue is at max capacity)
    var shouldPauseGeneration: Bool { queueCount >= config.maxQueueSize }
    
    /// Whether generation should resume (queue is below minimum)
    var shouldResumeGeneration: Bool { queueCount < config.minQueueSize }
    
    private let fileManager = FileManager.default
    private let operationQueue = DispatchQueue(label: "SpeechQueueManager.operations", qos: .utility)
    
    /// Creates a new queue manager with the specified configuration.
    /// - Parameter config: Queue configuration
    init(config: SpeechQueueConfiguration = .default) {
        self.config = config
        ensureDirectoriesExist()
    }
    
    // MARK: - Directory Management
    
    /// Ensures the queue and done directories exist.
    private func ensureDirectoriesExist() {
        do {
            try fileManager.createDirectory(at: config.queueDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: config.doneDirectory, withIntermediateDirectories: true)
        } catch {
            print("⚠️ SpeechQueueManager: Failed to create directories: \(error)")
        }
    }
    
    // MARK: - Queue Scanning
    
    /// Scans the queue directory and updates the available sets.
    /// - Returns: Array of available conversation sets
    @discardableResult
    func scanQueue() -> [ConversationSet] {
        isScanning = true
        defer { isScanning = false }
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: config.queueDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            var sets: [ConversationSet] = []
            
            for url in contents {
                // Skip the DONE directory
                if url.lastPathComponent == "DONE" { continue }
                
                // Skip in-progress markers
                if url.lastPathComponent.hasSuffix(".inprogress") { continue }
                
                // Attempt to create a valid conversation set
                if let set = ConversationSet(folderURL: url) {
                    sets.append(set)
                }
            }
            
            // Sort by creation time (oldest first)
            sets.sort()
            availableSets = sets
            
            return sets
        } catch {
            print("⚠️ SpeechQueueManager: Failed to scan queue: \(error)")
            return []
        }
    }
    
    // MARK: - Set Consumption
    
    /// Consumes the oldest conversation set from the queue.
    /// The set is marked as in-progress to prevent concurrent consumption.
    /// - Returns: The oldest conversation set, or nil if queue is empty
    func consumeOldest() -> ConversationSet? {
        scanQueue()
        
        guard let oldest = availableSets.first else {
            return nil
        }
        
        // Mark as in-progress by renaming
        let inProgressURL = oldest.folderURL.appendingPathExtension("inprogress")
        
        do {
            try fileManager.moveItem(at: oldest.folderURL, to: inProgressURL)
            
            // Create a new ConversationSet pointing to the in-progress location
            // Note: The folder validation will skip .inprogress folders during scan,
            // so we create it directly here
            let inProgressSet = ConversationSet(
                id: oldest.id,
                folderURL: inProgressURL,
                startFile: inProgressURL.appendingPathComponent("start.wav"),
                middleFiles: oldest.middleFiles.map { originalURL in
                    inProgressURL.appendingPathComponent(originalURL.lastPathComponent)
                },
                endFile: inProgressURL.appendingPathComponent("end.wav"),
                createdAt: oldest.createdAt
            )
            
            currentSet = inProgressSet
            
            // Remove from available sets
            availableSets.removeFirst()
            
            return inProgressSet
        } catch {
            print("⚠️ SpeechQueueManager: Failed to mark set as in-progress: \(error)")
            return nil
        }
    }
    
    /// Returns the oldest set without consuming it (peek operation).
    /// - Returns: The oldest conversation set, or nil if queue is empty
    func peekOldest() -> ConversationSet? {
        scanQueue()
        return availableSets.first
    }
    
    // MARK: - Set Completion
    
    /// Moves a consumed set to the DONE folder.
    /// - Parameter set: The conversation set to mark as completed
    func moveToCompleted(_ set: ConversationSet) {
        let destinationURL = config.doneDirectory.appendingPathComponent(set.id)
        
        do {
            // Remove the .inprogress extension if present
            let sourceURL = set.folderURL
            
            // Ensure destination doesn't exist
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            
            if currentSet?.id == set.id {
                currentSet = nil
            }
            
            // Prune old completed sets
            pruneCompletedSets()
        } catch {
            print("⚠️ SpeechQueueManager: Failed to move set to completed: \(error)")
        }
    }
    
    /// Discards a set (removes it entirely without moving to DONE).
    /// Useful for malformed or partial sets.
    /// - Parameter set: The conversation set to discard
    func discardSet(_ set: ConversationSet) {
        do {
            try fileManager.removeItem(at: set.folderURL)
            
            if currentSet?.id == set.id {
                currentSet = nil
            }
        } catch {
            print("⚠️ SpeechQueueManager: Failed to discard set: \(error)")
        }
    }
    
    /// Releases the current set back to the queue (undo consume).
    /// - Parameter set: The conversation set to release
    func releaseCurrentSet(_ set: ConversationSet) {
        guard set.id == currentSet?.id else { return }
        
        // Remove .inprogress extension
        let originalURL = config.queueDirectory.appendingPathComponent(set.id)
        
        do {
            try fileManager.moveItem(at: set.folderURL, to: originalURL)
            currentSet = nil
            scanQueue()
        } catch {
            print("⚠️ SpeechQueueManager: Failed to release set: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    /// Prunes old completed sets, keeping only the most recent ones.
    /// - Parameter keepingLast: Number of sets to keep (defaults to config value)
    func pruneCompletedSets(keepingLast: Int? = nil) {
        let keepCount = keepingLast ?? config.maxDoneSetsToKeep
        
        operationQueue.async { [weak self] in
            guard let self else { return }
            
            do {
                let contents = try self.fileManager.contentsOfDirectory(
                    at: self.config.doneDirectory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                
                // Sort by name (which is a timestamp, so oldest first)
                let sorted = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
                
                // Remove oldest sets if we exceed the limit
                if sorted.count > keepCount {
                    let toRemove = sorted.prefix(sorted.count - keepCount)
                    for url in toRemove {
                        try self.fileManager.removeItem(at: url)
                    }
                }
            } catch {
                print("⚠️ SpeechQueueManager: Failed to prune completed sets: \(error)")
            }
        }
    }
    
    /// Cleans up any orphaned in-progress markers (from crashes).
    func cleanupOrphanedInProgress() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: config.queueDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for url in contents where url.pathExtension == "inprogress" {
                // Remove the .inprogress extension and put back in queue
                let originalName = url.deletingPathExtension().lastPathComponent
                let originalURL = config.queueDirectory.appendingPathComponent(originalName)
                
                if !fileManager.fileExists(atPath: originalURL.path) {
                    try fileManager.moveItem(at: url, to: originalURL)
                } else {
                    // Original exists, remove the orphan
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("⚠️ SpeechQueueManager: Failed to cleanup orphaned in-progress: \(error)")
        }
    }
}

// MARK: - Internal Initialization Extension

extension ConversationSet {
    /// Internal initializer for creating sets with known values (used by SpeechQueueManager).
    init(id: String, folderURL: URL, startFile: URL, middleFiles: [URL], endFile: URL, createdAt: Date) {
        self.id = id
        self.folderURL = folderURL
        self.startFile = startFile
        self.middleFiles = middleFiles
        self.endFile = endFile
        self.createdAt = createdAt
    }
}
