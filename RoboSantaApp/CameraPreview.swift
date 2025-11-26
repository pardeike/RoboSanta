import SwiftUI
import AVFoundation

final class PreviewHostView: NSView {
    let rootLayer = CALayer()
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = rootLayer
    }
    required init?(coder: NSCoder) { fatalError() }
}

struct CameraPreview: NSViewRepresentable {
    @EnvironmentObject var visionSource: VisionDetectionSource

    func makeNSView(context: Context) -> PreviewHostView {
        let v = PreviewHostView()
        visionSource.attach(to: v.rootLayer)
        return v
    }

    func updateNSView(_ nsView: PreviewHostView, context: Context) {
        // Layer autoresizes; nothing to do.
    }
}

/// Generic detection preview that can render either a real camera feed or a synthetic feed.
/// Uses DetectionPreviewProviding so virtual sources can draw simple overlays.
struct DetectionPreview: NSViewRepresentable {
    let source: DetectionPreviewProviding

    func makeNSView(context: Context) -> PreviewHostView {
        let view = PreviewHostView()
        source.attachPreview(to: view.rootLayer)
        return view
    }

    func updateNSView(_ nsView: PreviewHostView, context: Context) {
        // Layers resize automatically; nothing else to do.
    }
}
