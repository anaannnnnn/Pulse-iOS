#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Top-10 tile: a huge outlined rank number tucked behind a tall poster.
struct FeatureCard: View {
    let scene: Video
    let rank: Int
    var posterWidth: CGFloat = 120
    var posterHeight: CGFloat { (posterWidth * 1.5).rounded() }
    private var numberWidth: CGFloat { posterWidth * (rank >= 10 ? 1.05 : 0.62) }

    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        NavigationLink(value: Route.scene(scene)) {
            HStack(alignment: .bottom, spacing: -posterWidth * 0.12) {
                Text("\(rank)")
                    .font(.system(size: posterHeight * 0.92, weight: .black))
                    .tracking(rank >= 10 ? -posterHeight * 0.12 : 0)
                    .foregroundStyle(.black)
                    .shadow(color: .white, radius: 0, x: 2, y: 0)
                    .shadow(color: .white, radius: 0, x: -2, y: 0)
                    .shadow(color: .white, radius: 0, x: 0, y: 2)
                    .shadow(color: .white, radius: 0, x: 0, y: -2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: numberWidth, height: posterHeight, alignment: .bottomTrailing)
                    .offset(y: posterHeight * 0.06)
                Color.clear
                    .frame(width: posterWidth, height: posterHeight)
                    .overlay { PulseArt(scene.poster ?? scene.thumb, seed: scene.id) }
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom).allowsHitTesting(false)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(scene.title).font(.system(.caption, weight: .bold)).foregroundStyle(.white)
                            .lineLimit(2).padding(.horizontal, 8).padding(.bottom, 8)
                    }
                    .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
            }
        }
        .buttonStyle(.pressable)
        .zoomSource(id: scene.id, in: zoomNamespace)
        .contextMenu { Button("Play", systemImage: "play.fill") { player.play(scene) } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Number \(rank), \(scene.title)")
    }
}
#endif
