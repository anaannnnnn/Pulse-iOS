#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct HomeView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.zoomNamespace) private var zoomNamespace
    @State private var heroIndex = 0

    public init() {}

    private var greeting: LocalizedStringKey {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header
                content
            }
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await stores.home.load(force: true) }
        .task { await stores.home.load() }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                PulseMark(size: 22)
                Text(greeting).font(PulseFont.title(.title2)).foregroundStyle(Theme.text)
            }
            Spacer()
            Button { player.tonightOpen = true } label: { Image(systemName: "sparkles") }
                .buttonStyle(.pulseIcon)
                .accessibilityLabel("Tonight picks")
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch stores.home.state {
        case .idle, .loading:
            HomeSkeleton()
        case .failed(let error):
            ErrorStateView(error.errorDescription ?? "Couldn't load your library.") { Task { await stores.home.load(force: true) } }
        case .loaded(let feed):
            if stores.home.libraryIsEmpty {
                EmptyStateView("Your library is empty", message: "Connect pCloud or TorBox in Settings, then scan to add videos.",
                               systemImage: "externaldrive.badge.plus")
            } else {
                if !feed.hero.isEmpty { HeroCarousel(videos: feed.hero, index: $heroIndex) }
                stats(feed)
                ForEach(feed.rails.filter { !$0.items.isEmpty }) { rail in
                    RailView(rail: rail)
                }
            }
        }
    }

    @ViewBuilder
    private func stats(_ feed: HomeFeed) -> some View {
        if let facets = stores.library.facets {
            HStack(spacing: 12) {
                StatTile(value: facets.totals.scenes, label: "Videos")
                StatTile(value: facets.totals.matched, label: "Matched")
                StatTile(value: facets.totals.favorites, label: "Favourites")
            }
            .padding(.horizontal, Theme.Space.page)
        } else {
            Color.clear.frame(height: 0).task { await stores.library.loadFacets() }
        }
    }
}

struct StatTile: View {
    let value: Int
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(PulseFont.display(20, relativeTo: .title3))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .pulseGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct RailView: View {
    let rail: HomeRail
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(LocalizedStringKey(rail.title), action: seeAllAction)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: Theme.Space.rail) {
                    switch rail.kind {
                    case .performers:
                        ForEach(rail.performers) { PerformerBubble(performer: $0).pulseScrollReveal() }
                    case .scenes:
                        ForEach(rail.scenes) { SceneCard(scene: $0, width: 250).pulseScrollReveal() }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Theme.Space.page)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var seeAllAction: (() -> Void)? {
        guard let query = seeAllQuery else { return nil }
        return {
            stores.library.query = query
            router.tab = .library
        }
    }

    /// Rails that map to a library filter get a "See all" button.
    private var seeAllQuery: LibraryQuery? {
        var q = LibraryQuery()
        switch rail.id {
        case "continue": q.watched = .inprogress; q.sort = .lastWatched
        case "favorites": q.favoritesOnly = true
        case "unwatched": q.watched = .false
        case "recent": q.sort = .added
        default: return nil
        }
        return q
    }
}

struct HomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.surface)
                .frame(height: 360).overlay { Shimmer() }.clipShape(.rect(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, Theme.Space.page)
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface)
                            .frame(width: 250, height: 156).overlay { Shimmer() }.clipShape(.rect(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal, Theme.Space.page)
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
