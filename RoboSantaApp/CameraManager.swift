import Foundation
import AppKit
import Combine

@preconcurrency import AVFoundation
@preconcurrency import Vision

final class CameraManager: NSObject, ObservableObject {

    @Published var devices: [AVCaptureDevice] = []
    @Published var selectedDeviceID: String?

    private let session = AVCaptureSession()
    private var input: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cam.session")
    private let videoQueue   = DispatchQueue(label: "cam.video")

    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let overlayLayer = CALayer()
    private var hasActiveFace = false
    private var lastFaceTimestamp: Date?
    private let lostThreshold: TimeInterval = 0.6

    private var visionBusy = false
    private let visionQueue = DispatchQueue(label: "cam.vision")

    // MARK: Lifecycle
    
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

        for connection in session.connections {
            guard connection.isVideoRotationAngleSupported(90) else { continue }
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()

        // some optional runtime tuning
        //
        // setFPS(30)
        // setLowLightBoost(true)
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

    // some optional tweaking methods
    /*
    func setExposureTargetBias(_ bias: Float) {
        guard let dev = input?.device else { return }
        sessionQueue.async {
            do {
                try dev.lockForConfiguration()
                dev.setExposureTargetBias(bias) { _ in dev.unlockForConfiguration() }
            } catch { print("Exposure bias unsupported: \(error)") }
        }
    }

    func setLowLightBoost(_ enabled: Bool) {
        guard let dev = input?.device else { return }
        sessionQueue.async {
            do {
                try dev.lockForConfiguration()
                if dev.isLowLightBoostSupported {
                    dev.automaticallyEnablesLowLightBoostWhenAvailable = enabled
                }
                dev.unlockForConfiguration()
            } catch { print("Low‑light boost error: \(error)") }
        }
    }

    func setFPS(_ fps: Double) {
        guard let dev = input?.device else { return }
        sessionQueue.async {
            do {
                try dev.lockForConfiguration()
                let duration = CMTimeMake(value: 1, timescale: Int32(max(1, min(240, fps))))
                dev.activeVideoMinFrameDuration = duration
                dev.activeVideoMaxFrameDuration = duration
                dev.unlockForConfiguration()
            } catch { print("FPS set error: \(error)") }
        }
    }

    func setCustomExposure(duration: CMTime, iso: Float) {
        guard let dev = input?.device, dev.isExposureModeSupported(.custom) else { return }
        sessionQueue.async {
            do {
                try dev.lockForConfiguration()
                //dev.setExposureModeCustom(duration: duration, iso: iso, completionHandler: nil)
                dev.unlockForConfiguration()
            } catch { print("Custom exposure error: \(error)") }
        }
    }
    */

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
            self.driveFigurine(with: faces)
        }
    }

    private func toPreviewRect(_ vnRect: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: vnRect)
    }
    
    private func driveFigurine(with faces: [(rect: CGRect, yawDeg: Double?)]) {
        let width = overlayLayer.bounds.width
        guard width > 0 else { return }
        if let candidate = faces.min(by: { abs(horizontalOffset(for: $0.rect, width: width)) < abs(horizontalOffset(for: $1.rect, width: width)) }) {
            hasActiveFace = true
            lastFaceTimestamp = Date()
            let offset = horizontalOffset(for: candidate.rect, width: width)
            let mirrored = videoOutput.connection(with: .video)?.isVideoMirrored == true
            santa.send(.personDetected(relativeOffset: mirrored ? -offset : offset))
        } else {
            guard hasActiveFace else { return }
            if let last = lastFaceTimestamp, Date().timeIntervalSince(last) < lostThreshold { return }
            hasActiveFace = false
            lastFaceTimestamp = nil
            santa.send(.personLost)
        }
    }
    
    private func horizontalOffset(for rect: CGRect, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        let normalized = (rect.midX / width) - 0.5
        let value = Double(normalized * 2)
        return max(-1.0, min(1.0, value))
    }
}

// MARK: - Capture delegate + Vision

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !visionBusy,
              let _ = input?.device,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        visionBusy = true

        let faceReq = VNDetectFaceRectanglesRequest()
        faceReq.revision = VNDetectFaceRectanglesRequest.currentRevision

        // Camera is rotated 90° counter-clockwise (portrait), so use .right orientation
        // .right means the image top is on the right side (90° CCW rotation)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

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
