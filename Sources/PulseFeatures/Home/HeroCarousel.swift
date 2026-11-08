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

    @ViewBuilder
    private var pager: some View {
        if videos.count > 1 {
            HStack(spacing: 6) {
                ForEach(videos.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: i == index ? 24 : 5, height: 4)
                        .overlay(alignment: .leading) {
                            if i == index {
                                Capsule().fill(Color.white).scaleEffect(x: max(progress, 0.001), anchor: .leading)
                            }
                        }
                }
            }
            .animation(Theme.glide, value: index)
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
    @State private var appeared = false
    @State private var drift = false

    var body: some View {
        ZStack(alignment: .bottom) {
            art
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black.opacity(0.55), location: 0.55), .init(color: .black, location: 1)], startPoint: .top, endPoint: .bottom).frame(height: height * 0.62).frame(maxHeight: .infinity, alignment: .bottom).allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 140).frame(maxHeight: .infinity, alignment: .top).allowsHitTesting(false)
            VStack(spacing: 12) {
                Text(video.title)
                    .font(.system(size: 34, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 2)
                    .blur(radius: appeared ? 0 : 12)
                    .scaleEffect(appeared ? 1 : 1.08)
                if !metaLine.isEmpty {
                    Text(metaLine).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                }
                actions.padding(.top, 6)
                Color.clear.frame(height: 22)
            }
            .padding(.horizontal, Theme.Space.page)
            .frame(maxWidth: .infinity)
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)
        }
        .frame(height: height)
        .clipped()
        .onAppear {
            withAnimation(.smooth(duration: 0.9).delay(0.1)) { appeared = true }
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private var art: some View {
        PulseArt(video.poster ?? video.thumb, seed: video.id)
            .frame(height: height)
            .visualEffect { content, proxy in
                content.offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX * 0.25)
            }
            .scaleEffect(drift ? 1.22 : 1.08)
    }

    /// My List / Play / Info, the classic three-up row.
    private var actions: some View {
        let saved = hub.isFavorite(video)
        return HStack(spacing: 0) {
            Button { Task { await hub.toggle(video) } } label: {
                VStack(spacing: 4) {
                    Image(systemName: saved ? "checkmark" : "plus").font(.system(size: 22, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text("My List").font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 72)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(saved ? "Remove from My List" : "Add to My List")
            Spacer(minLength: 12)
            Button { player.play(video) } label: {
                Label(video.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
                    .frame(minWidth: 96)
            }
            .buttonStyle(.pulsePrimary)
            Spacer(minLength: 12)
            NavigationLink(value: Route.scene(video)) {
                VStack(spacing: 4) {
                    Image(systemName: "info.circle").font(.system(size: 22, weight: .regular))
                    Text("Info").font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 72)
            }
            .buttonStyle(.pressable)
        }
        .frame(maxWidth: 340)
        .sensoryFeedback(.success, trigger: saved)
    }

    private var metaLine: String {
        ([video.studio?.name] + video.performers.prefix(2).map(\.name)).compactMap { $0 }.joined(separator: " · ")
    }
}
#endif
