// VisionDetectionSource.swift
// Wraps CameraManager to emit detection frames via PersonDetectionSource protocol.

import Foundation
import AppKit
import Combine
import CoreGraphics

@preconcurrency import AVFoundation
@preconcurrency import Vision

/// Vision-based detection source using the camera.
/// This class wraps the camera detection functionality and emits detection frames.
final class VisionDetectionSource: NSObject, PersonDetectionSource, ObservableObject {
    
    @Published var devices: [AVCaptureDevice] = []
    @Published var selectedDeviceID: String?
    
    private let session = AVCaptureSession()
    private var input: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "vision.session")
    private let videoQueue   = DispatchQueue(label: "vision.video")
    
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let overlayLayer = CALayer()
    
    private var visionBusy = false
    private let visionQueue = DispatchQueue(label: "vision.vision")
    
    private let detectionSubject = PassthroughSubject<DetectionFrame, Never>()
    
    @Published var portraitModeEnabled = false {
        didSet { applyOrientationMode() }
    }
    
    var detectionFrames: AnyPublisher<DetectionFrame, Never> {
        detectionSubject.eraseToAnyPublisher()
    }
    
    var supportsPreview: Bool { true }
    
    private var visionOrientation: CGImagePropertyOrientation {
        portraitModeEnabled ? .right : .up
    }
    
    private var rotationAngle: Double {
        portraitModeEnabled ? 90 : 0
    }
    
    // MARK: - PersonDetectionSource
    
    func start() {
        discoverDevices()
        configureSession()
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    // MARK: Device discovery and selection
    
    private func discoverDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        devices = discovery.devices
        if selectedDeviceID == nil {
            selectedDeviceID = devices
                .first(where: { $0.localizedName == "Webcam" })?
                .uniqueID
        }
    }
    
    func applySelection() {
        guard let id = selectedDeviceID, let dev = devices.first(where: { $0.uniqueID == id }) else { return }
        sessionQueue.async {
            self.session.beginConfiguration()
            if let old = self.input { self.session.removeInput(old) }
            do {
                let newInput = try AVCaptureDeviceInput(device: dev)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.input = newInput
                }
            } catch {
                print("Input error: \(error)")
            }
            self.applyOrientationAngleLocked()
            self.session.commitConfiguration()
        }
    }
    
    // MARK: Session and output
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        if let id = selectedDeviceID, let dev = devices.first(where: { $0.uniqueID == id }) {
            do {
                input = try AVCaptureDeviceInput(device: dev)
                if session.canAddInput(input!) { session.addInput(input!) }
            } catch { print("Input error: \(error)") }
        }
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                         kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        applyOrientationAngleLocked()
        session.commitConfiguration()
    }
    
    // MARK: Preview + overlay attach
    
    func attach(to hostLayer: CALayer) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspect
        hostLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        previewLayer.frame = hostLayer.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        hostLayer.addSublayer(previewLayer)
        
        overlayLayer.frame = hostLayer.bounds
        overlayLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        overlayLayer.masksToBounds = true
        hostLayer.addSublayer(overlayLayer)
    }
    
    // MARK: Drawing overlay
    
    private func showDetections(faces: [(rect: CGRect, yawDeg: Double?)]) {
        DispatchQueue.main.async {
            self.overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            func addBox(_ rect: CGRect, color: NSColor) {
                let shape = CAShapeLayer()
                shape.frame = rect
                shape.path = CGPath(rect: CGRect(origin: .zero, size: rect.size), transform: nil)
                shape.fillColor = NSColor.black.withAlphaComponent(0.25).cgColor
                shape.strokeColor = color.cgColor
                shape.lineWidth = 4.0
                self.overlayLayer.addSublayer(shape)
            }
            
            func addLabel(_ text: String, at rect: CGRect) {
                let tl = CATextLayer()
                tl.string = text
                tl.fontSize = 24
                tl.foregroundColor = NSColor.systemYellow.cgColor
                tl.alignmentMode = .left
                tl.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
                tl.frame = CGRect(x: rect.minX + 4, y: rect.minY - 20, width: 140, height: 48)
                self.overlayLayer.addSublayer(tl)
            }
            
            for f in faces {
                addBox(f.rect, color: .systemYellow)
                if let y = f.yawDeg {
                    addLabel(String(format: "%.0f°", y), at: f.rect)
                }
            }
            
            // Emit detection frame via publisher
            self.emitDetectionFrame(with: faces)
        }
    }
    
    private func emitDetectionFrame(with faces: [(rect: CGRect, yawDeg: Double?)]) {
        let width = overlayLayer.bounds.width
        let height = overlayLayer.bounds.height
        guard width > 0, height > 0 else { return }
        
        let mirrored = videoOutput.connection(with: .video)?.isVideoMirrored == true
        
        let detectedFaces = faces.map { face -> DetectedFace in
            let offset = horizontalOffset(for: face.rect, width: width)
            let mirroredOffset = mirrored ? -offset : offset
            return DetectedFace(
                boundingBoxNormalized: CGRect(
                    x: face.rect.minX / width,
                    y: face.rect.minY / height,
                    width: face.rect.width / width,
                    height: face.rect.height / height
                ),
                yawDeg: face.yawDeg,
                relativeOffset: mirroredOffset
            )
        }
        
        let frame = DetectionFrame(
            size: CGSize(width: width, height: height),
            faces: detectedFaces,
            previewImage: nil
        )
        
        detectionSubject.send(frame)
    }
    
    private func toPreviewRect(_ vnRect: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: vnRect)
    }
    
    private func horizontalOffset(for rect: CGRect, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        let normalized = (rect.midX / width) - 0.5
        let value = Double(normalized * 2)
        return max(-1.0, min(1.0, value))
    }
    
    private func applyOrientationMode() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.applyOrientationAngleLocked()
            self.session.commitConfiguration()
        }
    }
    
    private func applyOrientationAngleLocked() {
        let angle = rotationAngle
        for connection in session.connections {
            guard connection.isVideoRotationAngleSupported(angle) else { continue }
            connection.videoRotationAngle = angle
        }
    }
}

// MARK: - Capture delegate + Vision

extension VisionDetectionSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !visionBusy,
              let _ = input?.device,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        visionBusy = true
        
        let faceReq = VNDetectFaceRectanglesRequest()
        faceReq.revision = VNDetectFaceRectanglesRequest.currentRevision
        
        // Use landscape by default; enable portrait mode when the camera is rotated 90° CCW.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: visionOrientation, options: [:])
        
        visionQueue.async {
            defer { self.visionBusy = false }
            do {
                try handler.perform([faceReq])
                
                let faces: [(rect: CGRect, yawDeg: Double?)] =
                (faceReq.results)?.map { obs in
                    let rect = self.toPreviewRect(obs.boundingBox)
                    var yaw = (obs.yaw?.doubleValue ?? 0) * 180.0 / .pi // 0° ≈ straight
                    // Keep sign consistent for mirrored previews
                    if let conn = self.videoOutput.connection(with: .video), conn.isVideoMirrored {
                        yaw = -yaw
                    }
                    return (rect, yaw)
                } ?? []
                
                self.showDetections(faces: faces)
            } catch {
                // ignore transient errors
            }
        }
    }
}

// MARK: - Preview provider

extension VisionDetectionSource: DetectionPreviewProviding {
    func attachPreview(to layer: CALayer) {
        attach(to: layer)
    }
}
