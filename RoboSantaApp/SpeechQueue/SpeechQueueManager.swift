// SpeechQueueManager.swift
// Manages the filesystem-based queue of conversation sets.

import Foundation
import Observation

/// Manages the filesystem-based queue of conversation sets.
/// Responsible for scanning, consuming, and moving conversation sets.
/// Thread-safe for use from multiple actors/queues.
@Observable
final class SpeechQueueManager {
    
    /// Configuration for the queue
    let config: SpeechQueueConfiguration
    
    /// Currently available conversation sets (sorted oldest first)
    /// Note: Access is synchronized via the lock
    private(set) var availableSets: [ConversationSet] = []
    
    /// The set currently being consumed (marked as in-progress)
    private(set) var currentSet: ConversationSet?
    
    /// Whether the queue is currently being scanned
    private(set) var isScanning = false
    
    /// Last queue count logged to avoid noisy output
    private var lastLoggedQueueCount: Int = -1
    
    /// Number of available sets
    var queueCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return availableSets.count
    }
    
    /// Whether the queue has content available
    var hasContent: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !availableSets.isEmpty
    }
    
    /// Whether generation should be paused (queue is at max capacity)
    var shouldPauseGeneration: Bool {
        lock.lock()
        defer { lock.unlock() }
        return availableSets.count >= config.maxQueueSize
    }
    
    /// Whether generation should resume (queue is below minimum)
    var shouldResumeGeneration: Bool {
        lock.lock()
        defer { lock.unlock() }
        return availableSets.count < config.minQueueSize
    }
    
    private let fileManager = FileManager.default
    private let operationQueue = DispatchQueue(label: "SpeechQueueManager.operations", qos: .utility)
    private let lock = NSLock()
    
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
        lock.lock()
        isScanning = true
        lock.unlock()
        
        defer {
            lock.lock()
            isScanning = false
            lock.unlock()
        }
        
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
            
            lock.lock()
            availableSets = sets
            let newCount = sets.count
            let shouldLog = lastLoggedQueueCount != newCount
            lastLoggedQueueCount = newCount
            lock.unlock()
            
            if shouldLog {
                print("📬 SpeechQueue: \(newCount) pending set(s)")
            }
            
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
        
        lock.lock()
        guard let oldest = availableSets.first else {
            lock.unlock()
            return nil
        }
        lock.unlock()
        
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
                type: oldest.type,
                startFile: inProgressURL.appendingPathComponent("start.wav"),
                middleFiles: oldest.middleFiles.map { originalURL in
                    inProgressURL.appendingPathComponent(originalURL.lastPathComponent)
                },
                endFile: inProgressURL.appendingPathComponent("end.wav"),
                createdAt: oldest.createdAt
            )
            
            lock.lock()
            currentSet = inProgressSet
            // Remove from available sets
            if !availableSets.isEmpty {
                availableSets.removeFirst()
            }
            lock.unlock()
            
            print("📥 SpeechQueue: Consuming set \(oldest.id)")
            
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
        lock.lock()
        defer { lock.unlock() }
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
            
            lock.lock()
            if currentSet?.id == set.id {
                currentSet = nil
            }
            lock.unlock()
            
            // Prune old completed sets
            pruneCompletedSets()
            
            print("📦 SpeechQueue: Completed set \(set.id)")
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
            
            lock.lock()
            if currentSet?.id == set.id {
                currentSet = nil
            }
            lock.unlock()
            
            print("🗑️ SpeechQueue: Discarded set \(set.id)")
        } catch {
            print("⚠️ SpeechQueueManager: Failed to discard set: \(error)")
        }
    }
    
    /// Releases the current set back to the queue (undo consume).
    /// - Parameter set: The conversation set to release
    func releaseCurrentSet(_ set: ConversationSet) {
        lock.lock()
        guard set.id == currentSet?.id else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        // Remove .inprogress extension
        let originalURL = config.queueDirectory.appendingPathComponent(set.id)
        
        do {
            try fileManager.moveItem(at: set.folderURL, to: originalURL)
            lock.lock()
            currentSet = nil
            lock.unlock()
            scanQueue()
            print("↩️ SpeechQueue: Released set \(set.id) back to queue")
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
                    print("🧹 SpeechQueue: Restored orphaned in-progress set \(originalName)")
                } else {
                    // Original exists, remove the orphan
                    try fileManager.removeItem(at: url)
                    print("🧹 SpeechQueue: Removed duplicate in-progress marker for \(originalName)")
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
    init(id: String, folderURL: URL, type: InteractionType, startFile: URL, middleFiles: [URL], endFile: URL, createdAt: Date) {
        self.id = id
        self.folderURL = folderURL
        self.type = type
        self.startFile = startFile
        self.middleFiles = middleFiles
        self.endFile = endFile
        self.createdAt = createdAt
    }
}
