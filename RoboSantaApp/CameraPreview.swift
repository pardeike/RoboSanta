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
    @EnvironmentObject var camera: CameraManager

    func makeNSView(context: Context) -> PreviewHostView {
        let v = PreviewHostView()
        camera.attach(to: v.rootLayer)
        return v
    }

    func updateNSView(_ nsView: PreviewHostView, context: Context) {
        // Layer autoresizes; nothing to do.
    }
}
