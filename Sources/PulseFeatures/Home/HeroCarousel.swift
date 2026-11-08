#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Edge-to-edge featured pager. The picture trails the text as you swipe, the pager snaps page by page with a haptic,
/// and the actions are Liquid Glass.
struct HeroCarousel: View {
    let videos: [Video]
    let height: CGFloat
    @Binding var index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    private let dwell: Double = 6

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(videos) { video in
                    HeroSlide(video: video, height: height)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content.opacity(reduceMotion ? 1 : 1 - abs(phase.value) * 0.6)
                                .scaleEffect(reduceMotion ? 1 : 1 - abs(phase.value) * 0.05)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(get: { videos.indices.contains(index) ? videos[index].id : nil },
                                    set: { id in if let i = videos.firstIndex(where: { $0.id == id }) { index = i } }))
        .frame(height: height)
        .overlay(alignment: .bottom) { pager }
        .sensoryFeedback(.selection, trigger: index)
        .task(id: "\(index)-\(reduceMotion)") {
            progress = 0
            guard videos.count > 1, !reduceMotion else { progress = 1; return }
            withAnimation(.linear(duration: dwell)) { progress = 1 }
            try? await Task.sleep(for: .seconds(dwell))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.8)) { index = (index + 1) % videos.count }
        }
        .visualEffect { content, proxy in
            // Pulling down stretches the picture instead of exposing a gap.
            let pull = max(proxy.frame(in: .scrollView(axis: .vertical)).minY, 0)
            return content.scaleEffect(reduceMotion ? 1 : 1 + pull / 700, anchor: .bottom)
        }
    }

    @ViewBuilder
    private var pager: some View {
        if videos.count > 1 {
            HStack(spacing: 6) {
                ForEach(videos.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: i == index ? 32 : 6, height: 6)
                        .overlay(alignment: .leading) {
                            if i == index {
                                Capsule().fill(Color.white).scaleEffect(x: max(progress, 0.001), anchor: .leading)
                            }
                        }
                }
            }
            .animation(reduceMotion ? nil : Theme.glide, value: index)
            .padding(.bottom, 8)
            .accessibilityHidden(true)
        }
    }
}

private struct HeroSlide: View {
    let video: Video
    let height: CGFloat
    @Environment(PlayerCoordinator.self) private var player
    @Environment(FavoritesHub.self) private var hub
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var appeared = false
    @State private var drift = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            art
            Theme.scrim.frame(height: height * 0.6).frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 140).frame(maxHeight: .infinity, alignment: .top).allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 12) {
                PulseGlassGroup(spacing: 8) {
                    HStack(spacing: 8) {
                        Chip("Featured", systemImage: "sparkle")
                        if let r = video.resolutionLabel { Chip(LocalizedStringKey(r)) }
                        if let runtime = Format.runtime(video.duration) { Chip(LocalizedStringKey(runtime), systemImage: "clock") }
                    }
                }
                Text(video.title)
                    .font(.largeTitle.bold())
                    .tracking(-0.4)
                    .foregroundStyle(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 2)
                    .blur(radius: appeared ? 0 : 12)
                    .scaleEffect(appeared ? 1 : 1.08, anchor: .leading)
                if !metaLine.isEmpty {
                    Text(metaLine).font(.subheadline).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                }
                actions.padding(.top, 4)
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, Theme.Space.page)
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)
        }
        .frame(height: height)
        .clipped()
        .task(id: reduceMotion) {
            if reduceMotion {
                appeared = true
                drift = false
            } else {
                withAnimation(Theme.entrance.delay(0.1)) { appeared = true }
                withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) { drift = true }
            }
        }
    }

    private var art: some View {
        PulseArt(video.poster ?? video.thumb, seed: video.id)
            .frame(height: height)
            .visualEffect { content, proxy in
                content.offset(x: reduceMotion ? 0 : -proxy.frame(in: .scrollView(axis: .horizontal)).minX * 0.25)
            }
            .scaleEffect(drift ? 1.22 : 1.08)
    }

    private var actions: some View {
        PulseGlassGroup(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { playButton; detailsButton; favoriteButton }
                VStack(alignment: .leading, spacing: 8) {
                    playButton
                    HStack(spacing: 12) { detailsButton; favoriteButton }
                }
            }
        }
    }

    private var playButton: some View {
        Button { player.play(video) } label: {
            Label(video.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
        }
        .buttonStyle(.pulsePrimary)
    }

    private var detailsButton: some View {
        NavigationLink(value: Route.scene(video)) {
            Label("Details", systemImage: "info.circle")
        }
        .buttonStyle(.pulseGlass)
    }

    private var favoriteButton: some View {
        Button { Task { await hub.toggle(video) } } label: {
            Image(systemName: hub.isFavorite(video) ? "heart.fill" : "heart")
                .symbolEffect(.bounce, value: hub.isFavorite(video))
        }
        .buttonStyle(.pulseIcon(isOn: hub.isFavorite(video), tint: Theme.ember))
        .accessibilityLabel(hub.isFavorite(video) ? "Remove favourite" : "Favourite")
    }

    private var metaLine: String {
        ([video.studio?.name] + video.performers.prefix(2).map(\.name)).compactMap { $0 }.joined(separator: " · ")
    }
}
#endif
