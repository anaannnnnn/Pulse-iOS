#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Full-width glass banner. Swipe between up to five featured videos.
struct HeroCarousel: View {
    let videos: [Video]
    @Binding var index: Int
    @Environment(PlayerCoordinator.self) private var player
    @Environment(FavoritesHub.self) private var hub
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(videos) { video in
                        HeroSlide(video: video)
                            .containerRelativeFrame(.horizontal) { width, _ in width - Theme.Space.page * 2 }
                            .scrollTransition(.animated(.smooth)) { content, phase in
                                content.scaleEffect(phase.isIdentity ? 1 : 0.93).opacity(phase.isIdentity ? 1 : 0.55)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, Theme.Space.page, for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(get: { videos.indices.contains(index) ? videos[index].id : nil },
                                        set: { id in if let i = videos.firstIndex(where: { $0.id == id }) { index = i } }))
            if videos.count > 1 {
                HStack(spacing: 6) {
                    ForEach(videos.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Color.white.opacity(0.22)))
                            .frame(width: i == index ? 22 : 6, height: 6)
                    }
                }
                .animation(.snappy, value: index)
                .accessibilityHidden(true)
                .sensoryFeedback(.selection, trigger: index)
            }
        }
    }
}

private struct HeroSlide: View {
    let video: Video
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        NavigationLink(value: Route.scene(video)) {
            Color.clear.aspectRatio(4 / 5, contentMode: .fit)
                .overlay { PulseArt(video.poster ?? video.thumb, seed: video.id) }
                .overlay { Theme.scrim }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            if let r = video.resolutionLabel { Chip(LocalizedStringKey(r)) }
                            if let runtime = Format.runtime(video.duration) { Chip(LocalizedStringKey(runtime), systemImage: "clock") }
                        }
                        Text(video.title)
                            .font(PulseFont.display(24, relativeTo: .title))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        if !metaLine.isEmpty { Text(metaLine).font(.subheadline).foregroundStyle(.white.opacity(0.78)).lineLimit(1) }
                        Button { player.play(video) } label: {
                            Label(video.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.pulsePrimary)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .clipShape(.rect(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Theme.lineStrong))
                .shadow(color: Theme.accent.opacity(0.25), radius: 24, y: 12)
        }
        .buttonStyle(.pressable)
        .zoomSource(id: video.id, in: zoomNamespace)
        .accessibilityLabel("\(video.title). Featured.")
    }

    private var metaLine: String {
        ([video.studio?.name] + video.performers.prefix(2).map(\.name)).compactMap { $0 }.joined(separator: " · ")
    }
}
#endif
