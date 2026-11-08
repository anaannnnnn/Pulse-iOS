#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Tall editorial card for curved carousels: full-bleed art, glass round buttons in the corners,
/// cast avatars and a serif title on a warm fade.
struct FeatureCard: View {
    let scene: Video
    var width: CGFloat = 280
    var height: CGFloat { (width * 1.38).rounded() }

    @Environment(FavoritesHub.self) private var hub
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        ZStack {
            NavigationLink(value: Route.scene(scene)) { face }
                .buttonStyle(.pressable)
                .zoomSource(id: scene.id, in: zoomNamespace)
            HStack {
                Button { Task { await hub.toggle(scene) } } label: {
                    Image(systemName: hub.isFavorite(scene) ? "heart.fill" : "heart").symbolEffect(.bounce, value: hub.isFavorite(scene))
                }
                .buttonStyle(.pulseIcon(isOn: hub.isFavorite(scene), tint: Theme.ember))
                .accessibilityLabel(hub.isFavorite(scene) ? "Remove favourite" : "Favourite")
                Spacer()
                Button { player.play(scene) } label: { Image(systemName: "play.fill") }
                    .buttonStyle(.pulseIcon)
                    .accessibilityLabel("Play")
            }
            .padding(12)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: width, height: height)
        .contextMenu {
            Button("Play", systemImage: "play.fill") { player.play(scene) }
        }
    }

    private var face: some View {
        Color.clear
            .overlay { PulseArt(scene.poster ?? scene.thumb, seed: scene.id) }
            .pulseSheen(strength: 0.26)
            .overlay {
                LinearGradient(stops: [.init(color: .clear, location: 0.4), .init(color: .black.opacity(0.7), location: 0.78),
                                       .init(color: .black.opacity(0.92), location: 1)], startPoint: .top, endPoint: .bottom)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
                    if !scene.performers.isEmpty { cast }
                    Text(scene.title)
                        .font(PulseFont.serif(.title))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    VStack(spacing: 6) {
                        if let runtime = Format.runtime(scene.duration) { metaRow("clock", runtime) }
                        if let studio = scene.studio?.name { metaRow("building.2", studio) }
                    }
                    if let p = scene.progress, !p.completed, p.fraction > 0 {
                        Capsule().fill(.white.opacity(0.2)).frame(height: 4)
                            .overlay(alignment: .leading) { GeometryReader { g in Capsule().fill(Theme.gradient).frame(width: g.size.width * p.fraction) } }
                            .padding(.horizontal, 30)
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 20)
            }
            .clipShape(.rect(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(Theme.rim, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 24, y: 14)
    }

    private var cast: some View {
        let shown = Array(scene.performers.prefix(4))
        return VStack(spacing: 5) {
            HStack(spacing: -10) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, p in
                    PulseArt(p.image, seed: p.id)
                        .frame(width: i == shown.count / 2 ? 38 : 30, height: i == shown.count / 2 ? 38 : 30)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.5))
                        .zIndex(i == shown.count / 2 ? 1 : 0)
                }
            }
            Text("+\(scene.performers.count) cast").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.7))
        }
    }

    private func metaRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption.weight(.semibold))
            Text(text).font(.footnote.weight(.medium)).lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.82))
    }
}
#endif
