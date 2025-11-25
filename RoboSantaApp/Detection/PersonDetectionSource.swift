// PersonDetectionSource.swift
// Protocol for person detection sources (camera or virtual).

import Foundation
import CoreGraphics
import Combine

/// Represents a detected face in camera/virtual space.
struct DetectedFace: Equatable {
    /// Normalized bounding box (0...1 in both dimensions)
    let boundingBoxNormalized: CGRect
    /// Face yaw in degrees (nil if not available)
    let yawDeg: Double?
    /// Horizontal offset from center (-1...+1)
    let relativeOffset: Double
}

/// Represents a single frame of detection results.
struct DetectionFrame {
    /// Frame size in pixels
    let size: CGSize
    /// Detected faces in this frame
    let faces: [DetectedFace]
    /// Optional preview image for UI rendering
    let previewImage: CGImage?
}

/// Protocol for person detection sources (camera or virtual).
protocol PersonDetectionSource {
    /// Publisher that emits detection frames
    var detectionFrames: AnyPublisher<DetectionFrame, Never> { get }
    
    /// Whether this detection source supports UI preview (e.g., camera preview)
    var supportsPreview: Bool { get }
    
    /// Start detection
    func start()
    
    /// Stop detection
    func stop()
}
