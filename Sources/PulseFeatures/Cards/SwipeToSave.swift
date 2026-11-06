#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Swipe a row left to reveal Favourite and Watchlist on glass buttons. A long swipe favourites straight away.
struct SwipeToSave: ViewModifier {
    let scene: Video
    @Environment(FavoritesHub.self) private var hub
    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    @State private var armed = false

    private let reveal: CGFloat = 112

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .background(alignment: .trailing) { actions }
            .simultaneousGesture(
                DragGesture(minimumDistance: 16)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.4 else { return }
                        let base: CGFloat = isOpen ? -reveal : 0
                        offset = min(0, max(-reveal * 1.8, base + value.translation.width))
                        armed = offset < -reveal * 1.5
                    }
                    .onEnded { _ in
                        if armed {
                            Task { await hub.toggle(scene) }
                            close()
                        } else if offset < -reveal / 2 {
                            withAnimation(Theme.glide) { offset = -reveal; isOpen = true }
                        } else {
                            close()
                        }
                    }
            )
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.7), trigger: armed) { _, now in now }
    }

    private var actions: some View {
        let progress = min(1, -offset / reveal)
        return PulseGlassGroup(spacing: 8) {
            HStack(spacing: 8) {
                Button { Task { await hub.toggle(scene) }; close() } label: {
                    Image(systemName: hub.isFavorite(scene) ? "heart.fill" : "heart")
                }
                .buttonStyle(.pulseIcon(isOn: hub.isFavorite(scene), tint: Theme.ember))
                .accessibilityLabel("Favourite")
                Button { Task { await hub.toggle(scene, list: .watchlist) }; close() } label: {
                    Image(systemName: hub.isWatchlisted(scene) ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.pulseIcon(isOn: hub.isWatchlisted(scene)))
                .accessibilityLabel("Watchlist")
            }
        }
        .padding(.trailing, 8)
        .opacity(progress)
        .scaleEffect(0.7 + 0.3 * progress)
        .allowsHitTesting(isOpen)
    }

    private func close() {
        withAnimation(Theme.glide) { offset = 0; isOpen = false; armed = false }
    }
}

extension View {
    func swipeToSave(_ scene: Video) -> some View { modifier(SwipeToSave(scene: scene)) }
}
#endif
