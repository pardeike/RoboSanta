// AudioPlayer.swift
// Handles WAV file playback for conversation sets.

import Foundation
import AVFoundation
import Observation

/// Playback state for the audio player.
enum AudioPlaybackState: Equatable, Sendable {
    case idle
    case playing(URL)
    case completed
    case interrupted
    case error(String)
}

/// Handles sequential playback of WAV audio files.
/// Designed for playing conversation set phrases with proper state tracking.
@Observable
@MainActor
final class AudioPlayer: NSObject {
    
    /// Current playback state
    private(set) var state: AudioPlaybackState = .idle
    
    /// Whether audio is currently playing
    var isPlaying: Bool {
        if case .playing = state { return true }
        return false
    }
    
    /// Volume level (0.0 to 1.0)
    var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackContinuation: CheckedContinuation<Bool, Never>?
    private var currentURL: URL?
    
    // MARK: - Playback Control
    
    /// Plays an audio file asynchronously and waits for completion.
    /// - Parameter fileURL: URL to the WAV file to play
    /// - Returns: true if playback completed successfully, false if interrupted or failed
    func play(_ fileURL: URL) async -> Bool {
        // Stop any existing playback
        stopInternal()
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            state = .error("File not found: \(fileURL.path)")
            return false
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            
            currentURL = fileURL
            state = .playing(fileURL)
            
            let success = audioPlayer?.play() ?? false
            
            if !success {
                state = .error("Failed to start playback")
                return false
            }
            
            // Wait for completion
            return await withCheckedContinuation { continuation in
                self.playbackContinuation = continuation
            }
        } catch {
            state = .error(error.localizedDescription)
            return false
        }
    }
    
    /// Plays an audio file and waits for completion.
    /// Convenience method for Fire-and-forget style playback.
    /// - Parameter fileURL: URL to the WAV file to play
    func playAndWait(_ fileURL: URL) async {
        _ = await play(fileURL)
    }
    
    /// Stops current playback immediately.
    func stop() {
        guard isPlaying else { return }
        
        state = .interrupted
        stopInternal()
        
        // Resume continuation with failure
        playbackContinuation?.resume(returning: false)
        playbackContinuation = nil
    }
    
    /// Waits for current playback to complete.
    /// - Returns: true if playback completed successfully, false if interrupted
    func waitForCompletion() async -> Bool {
        guard isPlaying else {
            return state == .completed
        }
        
        return await withCheckedContinuation { continuation in
            if self.playbackContinuation != nil {
                // Already waiting, just return current state
                continuation.resume(returning: false)
            } else {
                self.playbackContinuation = continuation
            }
        }
    }
    
    /// Resets the player to idle state.
    func reset() {
        stopInternal()
        state = .idle
        currentURL = nil
    }
    
    // MARK: - Private Methods
    
    private func stopInternal() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func handlePlaybackFinished(successfully: Bool) {
        if successfully {
            state = .completed
        } else if case .playing = state {
            // Only set interrupted if we were still in playing state
            state = .interrupted
        }
        
        audioPlayer = nil
        currentURL = nil
        
        playbackContinuation?.resume(returning: successfully)
        playbackContinuation = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            handlePlaybackFinished(successfully: flag)
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            state = .error(error?.localizedDescription ?? "Decode error")
            handlePlaybackFinished(successfully: false)
        }
    }
}

// MARK: - Convenience Extensions

extension AudioPlayer {
    /// Plays a sequence of audio files in order.
    /// Stops immediately if any file fails or if interrupted.
    /// - Parameter files: Array of URLs to play in sequence
    /// - Returns: Number of files successfully played
    func playSequence(_ files: [URL]) async -> Int {
        var playedCount = 0
        
        for file in files {
            let success = await play(file)
            if success {
                playedCount += 1
            } else {
                break
            }
        }
        
        return playedCount
    }
    
    /// Plays a conversation set's start file.
    /// - Parameter set: The conversation set
    /// - Returns: true if playback completed successfully
    func playStart(of set: ConversationSet) async -> Bool {
        return await play(set.startFile)
    }
    
    /// Plays all middle files of a conversation set in sequence.
    /// - Parameter set: The conversation set
    /// - Returns: Number of middle files successfully played
    func playMiddles(of set: ConversationSet) async -> Int {
        return await playSequence(set.middleFiles)
    }
    
    /// Plays a conversation set's end file.
    /// - Parameter set: The conversation set
    /// - Returns: true if playback completed successfully
    func playEnd(of set: ConversationSet) async -> Bool {
        return await play(set.endFile)
    }
}
