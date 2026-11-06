#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Edge-to-edge featured pager. Artwork slides at a different speed to the text (parallax), the title sits on a
/// photographic fade, and the actions are a white Play pill, a glass Details pill and a heart.
struct HeroCarousel: View {
    let videos: [Video]
    @Binding var index: Int

    static let height: CGFloat = 600

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(videos) { video in
                    HeroSlide(video: video)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content.opacity(1 - abs(phase.value) * 0.55).scaleEffect(1 - abs(phase.value) * 0.06)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(get: { videos.indices.contains(index) ? videos[index].id : nil },
                                    set: { id in if let i = videos.firstIndex(where: { $0.id == id }) { index = i } }))
        .frame(height: Self.height)
        .overlay(alignment: .bottom) { pager }
        .sensoryFeedback(.selection, trigger: index)
    }

    @ViewBuilder
    private var pager: some View {
        if videos.count > 1 {
            HStack(spacing: 6) {
                ForEach(videos.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Color.white.opacity(0.28)))
                        .frame(width: i == index ? 26 : 6, height: 6)
                        .shadow(color: i == index ? Theme.accent.opacity(0.6) : .clear, radius: 6)
                }
            }
            .animation(Theme.glide, value: index)
            .padding(.bottom, 10)
            .accessibilityHidden(true)
        }
    }
}

private struct HeroSlide: View {
    let video: Video
    @Environment(PlayerCoordinator.self) private var player
    @Environment(FavoritesHub.self) private var hub
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            art
            Theme.scrim.frame(height: HeroCarousel.height * 0.62).frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 150).frame(maxHeight: .infinity, alignment: .top).allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Chip("Featured", systemImage: "sparkle", tint: Theme.accent)
                    if let r = video.resolutionLabel { Chip(LocalizedStringKey(r)) }
                    if let runtime = Format.runtime(video.duration) { Chip(LocalizedStringKey(runtime), systemImage: "clock") }
                }
                Text(video.title)
                    .font(PulseFont.display(36, relativeTo: .largeTitle, weight: .heavy))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                if !metaLine.isEmpty {
                    Text(metaLine).font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                }
                actions.padding(.top, 6)
                Color.clear.frame(height: 18)
            }
            .padding(.horizontal, Theme.Space.page)
            .offset(y: appeared ? 0 : 26)
            .opacity(appeared ? 1 : 0)
        }
        .frame(height: HeroCarousel.height)
        .clipped()
        .onAppear { withAnimation(.smooth(duration: 0.7).delay(0.1)) { appeared = true } }
    }

    private var art: some View {
        PulseArt(video.poster ?? video.thumb, seed: video.id)
            .frame(height: HeroCarousel.height)
            .visualEffect { content, proxy in
                // Slower than the page: the picture trails the text as you swipe.
                content.offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX * 0.28).scaleEffect(1.12)
            }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button { player.play(video) } label: {
                Label(video.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
            }
            .buttonStyle(.pulseLight)
            NavigationLink(value: Route.scene(video)) {
                Label("Details", systemImage: "info.circle")
            }
            .buttonStyle(.pulseGlass)
            Button { Task { await hub.toggle(video) } } label: {
                Image(systemName: hub.isFavorite(video) ? "heart.fill" : "heart")
                    .symbolEffect(.bounce, value: hub.isFavorite(video))
            }
            .buttonStyle(.pulseIcon(isOn: hub.isFavorite(video), tint: Theme.ember))
            .accessibilityLabel(hub.isFavorite(video) ? "Remove favourite" : "Favourite")
        }
    }

    private var metaLine: String {
        ([video.studio?.name] + video.performers.prefix(2).map(\.name)).compactMap { $0 }.joined(separator: " · ")
    }
}
#endif
