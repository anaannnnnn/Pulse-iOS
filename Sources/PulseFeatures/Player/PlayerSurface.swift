#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import AVFoundation
import AVKit

/// Hosts the AVPlayerLayer. The only UIKit in the app besides the AirPlay picker.
struct PlayerSurface: UIViewRepresentable {
    let engine: PlayerEngine
    var fill: Bool

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = engine.player
        view.backgroundColor = .black
        engine.attach(layer: view.playerLayer)
        return view
    }

    func updateUIView(_ view: PlayerLayerView, context: Context) {
        view.playerLayer.videoGravity = fill ? .resizeAspectFill : .resizeAspect
    }
}

final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1)
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif
