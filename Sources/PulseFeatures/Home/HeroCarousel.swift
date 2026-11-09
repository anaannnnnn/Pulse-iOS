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
                            content.opacity(1 - abs(phase.value) * 0.6).scaleEffect(1 - abs(phase.value) * 0.05)
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
        .task(id: index) {
            progress = 0
            guard videos.count > 1, !reduceMotion else { return }
            withAnimation(.linear(duration: dwell)) { progress = 1 }
            try? await Task.sleep(for: .seconds(dwell))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.8)) { index = (index + 1) % videos.count }
        }
        .visualEffect { content, proxy in
            // Pulling down stretches the picture instead of exposing a gap.
            let pull = max(proxy.frame(in: .scrollView(axis: .vertical)).minY, 0)
            return content.scaleEffect(1 + pull / 700, anchor: .bottom)
        }
    }

    /// Film-strip pager: one tick per feature, the live one is taller and fills like a frame counter.
    @ViewBuilder
    private var pager: some View {
        if videos.count > 1 {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(videos.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 3, height: i == index ? 22 : 11)
                        .overlay(alignment: .bottom) {
                            if i == index {
                                Capsule().fill(Theme.accent).scaleEffect(y: max(progress, 0.001), anchor: .bottom)
                            }
                        }
                }
            }
            .animation(Theme.glide, value: index)
            .padding(.trailing, Theme.Space.page)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, alignment: .trailing)
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
    @State private var appeared = false
    @State private var drift = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            art
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black.opacity(0.6), location: 0.5), .init(color: .black, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: height * 0.7).frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 140).frame(maxHeight: .infinity, alignment: .top).allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 10) {
                if let meta = timecodeLine {
                    Text(meta)
                        .font(PulseFont.timecode(.caption))
                        .foregroundStyle(Theme.accentSoft)
                        .lineLimit(1)
                }
                Text(video.title)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 2)
                if !castLine.isEmpty {
                    Text(castLine).font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                }
                actions.padding(.top, 6)
                Color.clear.frame(height: 26)
            }
            .padding(.horizontal, Theme.Space.page)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: appeared ? 0 : 18)
            .opacity(appeared ? 1 : 0)
        }
        .frame(height: height)
        .clipped()
        .onAppear {
            let enter: Animation? = reduceMotion ? nil : Animation.smooth(duration: 0.8).delay(0.08)
            withAnimation(enter) { appeared = true }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private var art: some View {
        PulseArt(video.poster ?? video.thumb, seed: video.id)
            .frame(height: height)
            .visualEffect { content, proxy in
                content.offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX * 0.25)
            }
            .scaleEffect(drift ? 1.2 : 1.08)
    }

    /// Play leads. Add to list and info are glass circles that share one container so they blend as they press.
    private var actions: some View {
        let saved = hub.isFavorite(video)
        return PulseGlassGroup(spacing: 10) {
            HStack(spacing: 10) {
                Button { player.play(video) } label: {
                    Label(video.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
                        .lineLimit(1)
                }
                .buttonStyle(.pulsePrimary)
                Button { Task { await hub.toggle(video) } } label: {
                    Image(systemName: saved ? "checkmark" : "plus").contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.pulseIcon(isOn: saved))
                .accessibilityLabel(saved ? "Remove from My List" : "Add to My List")
                NavigationLink(value: Route.scene(video)) { Image(systemName: "info") }
                    .buttonStyle(.pulseIcon)
                    .accessibilityLabel("Details")
            }
        }
        .sensoryFeedback(.success, trigger: saved)
    }

    private var timecodeLine: String? {
        let parts = [video.year.map(String.init), Format.runtime(video.duration), video.resolutionLabel].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  /  ")
    }

    private var castLine: String {
        ([video.studio?.name] + video.performers.prefix(2).map(\.name)).compactMap { $0 }.joined(separator: " · ")
    }
}
#endif
