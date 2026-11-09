#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Poster card: tall 2:3 tile by default (title on the art), landscape for "continue watching".
struct SceneCard: View {
    let scene: Video
    var width: CGFloat?
    /// Adds a centred play button (used by "Continue watching").
    var showsPlay = false
    /// Tall 2:3 poster with the title over the art, no caption underneath.
    var portrait = false
    @Environment(FavoritesHub.self) private var hub
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        NavigationLink(value: Route.scene(scene)) {
            VStack(alignment: .leading, spacing: 8) {
                artwork
                if !portrait { VStack(alignment: .leading, spacing: 3) {
                    Text(scene.title)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(2, reservesSpace: false)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                } }
            }
            .frame(width: width)
        }
        .buttonStyle(.pressable)
        .zoomSource(id: scene.id, in: zoomNamespace)
        .contextMenu { menu } preview: { SceneQuickLook(scene: scene) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens details")
    }

    private var artwork: some View {
        Color.clear
            .aspectRatio(portrait ? 2 / 3 : 16 / 10, contentMode: .fit)
            .overlay { PulseArt(scene.poster ?? scene.thumb, seed: scene.id) }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(portrait ? 0.85 : 0.55)], startPoint: .center, endPoint: .bottom).allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                if portrait {
                    Text(scene.title)
                        .font(.system(.caption, design: .serif, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 8).padding(.bottom, 8)
                }
            }
            .overlay {
                if showsPlay {
                    Image(systemName: "play.fill").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(.black.opacity(0.5), in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.5))
                }
            }
            .overlay(alignment: .topLeading) {
                if let label = scene.resolutionLabel, label == "4K" || label == "1440p" {
                    Text(label).font(.system(.caption2, design: .monospaced, weight: .bold)).foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.accent, in: Capsule()).padding(6)
                }
            }
            .overlay(alignment: .topTrailing) {
                if hub.isFavorite(scene) {
                    Image(systemName: "heart.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.ember)
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !portrait, let runtime = Format.runtime(scene.duration) {
                    Text(runtime)
                        .font(PulseFont.timecode(.caption2))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(8)
                }
            }
            .overlay(alignment: .bottom) {
                if let progress = scene.progress, !progress.completed, progress.fraction > 0 {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white.opacity(0.3))
                            Rectangle().fill(Theme.accent).frame(width: proxy.size.width * progress.fraction)
                        }
                        .frame(height: 3)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
            .animation(.snappy, value: hub.isFavorite(scene))
    }

    private var subtitle: String {
        [scene.studio?.name, scene.year.map(String.init)].compactMap { $0 }.joined(separator: " · ")
    }

    private var accessibilityLabel: String {
        var parts = [scene.title]
        if let studio = scene.studio?.name { parts.append(studio) }
        if let runtime = Format.runtime(scene.duration) { parts.append(runtime) }
        if let p = scene.progress, !p.completed, p.fraction > 0 { parts.append("\(Int(p.fraction * 100)) percent watched") }
        if hub.isFavorite(scene) { parts.append("Favourite") }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var menu: some View {
        Button("Play", systemImage: "play.fill") { player.play(scene) }
        Button(hub.isFavorite(scene) ? "Remove favourite" : "Favourite", systemImage: hub.isFavorite(scene) ? "heart.slash" : "heart") {
            Task { await hub.toggle(scene) }
        }
        Button(hub.isWatchlisted(scene) ? "Remove from watchlist" : "Add to watchlist",
               systemImage: hub.isWatchlisted(scene) ? "bookmark.slash" : "bookmark") {
            Task { await hub.toggle(scene, list: .watchlist) }
        }
    }
}

/// Larger peek shown by the context menu.
struct SceneQuickLook: View {
    let scene: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear.aspectRatio(16 / 9, contentMode: .fit)
                .overlay { PulseArt(scene.poster ?? scene.thumb, seed: scene.id) }
                .clipShape(.rect(cornerRadius: 16))
            Text(scene.title).font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            if let studio = scene.studio?.name { Text(studio).font(.subheadline).foregroundStyle(Theme.textSecondary) }
        }
        .padding(14)
        .frame(width: 320)
        .background(Theme.surface)
    }
}

/// Compact horizontal row for lists (search, watchlist, performer scenes).
struct SceneRow: View {
    let scene: Video
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        NavigationLink(value: Route.scene(scene)) {
            HStack(spacing: 14) {
                Color.clear.frame(width: 128).aspectRatio(16 / 10, contentMode: .fit)
                    .overlay { PulseArt(scene.poster ?? scene.thumb, seed: scene.id) }
                    .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.title).font(.system(.subheadline, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
                    Text([scene.studio?.name, Format.runtime(scene.duration)].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    if let p = scene.progress, !p.completed, p.fraction > 0 {
                        ProgressView(value: p.fraction).tint(Theme.accent)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "play.circle").font(.system(size: 30, weight: .light)).foregroundStyle(Theme.text)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.pressable)
        .zoomSource(id: scene.id, in: zoomNamespace)
        .swipeToSave(scene)
    }
}
#endif
