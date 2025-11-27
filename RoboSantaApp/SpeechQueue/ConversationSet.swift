// ConversationSet.swift
// Represents a single conversation set with start/middle/end audio files.

import Foundation

/// Represents a validated conversation set stored on the filesystem.
/// Each set consists of start.wav, optional middle*.wav files, and end.wav.
struct ConversationSet: Identifiable, Equatable, Sendable {
    /// Unique identifier (folder name, typically a timestamp like YYYYMMDDHHMMSS)
    let id: String
    
    /// Full path to the conversation set folder
    let folderURL: URL
    
    /// Path to the start phrase audio file
    let startFile: URL
    
    /// Paths to middle phrase audio files (sorted: middle1.wav, middle2.wav, ...)
    let middleFiles: [URL]
    
    /// Path to the end phrase audio file
    let endFile: URL
    
    /// Timestamp when this set was created (parsed from folder name)
    let createdAt: Date
    
    /// Total number of phrases in this set
    var totalPhrases: Int { 1 + middleFiles.count + 1 }
    
    /// Creates a ConversationSet by validating a folder's contents.
    /// Returns nil if the folder doesn't contain valid conversation files.
    /// - Parameter folderURL: URL to the conversation set folder
    init?(folderURL: URL) {
        let fileManager = FileManager.default
        
        // Validate folder exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }
        
        let folderName = folderURL.lastPathComponent
        
        // Skip folders that look like processing markers
        if folderName.hasSuffix(".inprogress") || folderName == "DONE" {
            return nil
        }
        
        // Validate required files exist
        let startURL = folderURL.appendingPathComponent("start.wav")
        let endURL = folderURL.appendingPathComponent("end.wav")
        
        guard fileManager.fileExists(atPath: startURL.path),
              fileManager.fileExists(atPath: endURL.path) else {
            return nil
        }
        
        // Find middle files (middle1.wav, middle2.wav, ..., middleN.wav)
        var middleURLs: [URL] = []
        var index = 1
        while true {
            let middleURL = folderURL.appendingPathComponent("middle\(index).wav")
            if fileManager.fileExists(atPath: middleURL.path) {
                middleURLs.append(middleURL)
                index += 1
            } else {
                break
            }
        }
        
        // Parse timestamp from folder name
        let createdDate = Self.parseTimestamp(from: folderName) ?? Date.distantPast
        
        self.id = folderName
        self.folderURL = folderURL
        self.startFile = startURL
        self.middleFiles = middleURLs
        self.endFile = endURL
        self.createdAt = createdDate
    }
    
    /// Validates that the folder name is a valid timestamp (YYYYMMDDHHMMSS format).
    /// - Parameter name: The folder name to validate
    /// - Returns: true if the name appears to be a valid timestamp
    static func isValidTimestamp(_ name: String) -> Bool {
        // Must be 14 digits
        guard name.count == 14, name.allSatisfy({ $0.isNumber }) else {
            return false
        }
        return parseTimestamp(from: name) != nil
    }
    
    /// Parses a timestamp string (YYYYMMDDHHMMSS) into a Date.
    /// - Parameter name: The timestamp string
    /// - Returns: The parsed Date, or nil if parsing fails
    private static func parseTimestamp(from name: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: name)
    }
    
    /// Generates a timestamp string for the current time.
    /// - Returns: A timestamp string in YYYYMMDDHHMMSS format
    static func generateTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    /// Creates a new folder URL for a conversation set with the current timestamp.
    /// - Parameter baseDirectory: The queue directory to create the folder in
    /// - Returns: URL for the new folder
    static func newFolderURL(in baseDirectory: URL) -> URL {
        return baseDirectory.appendingPathComponent(generateTimestamp())
    }
}

// MARK: - Comparable

extension ConversationSet: Comparable {
    static func < (lhs: ConversationSet, rhs: ConversationSet) -> Bool {
        // Sort by creation time, oldest first
        lhs.createdAt < rhs.createdAt
    }
}
