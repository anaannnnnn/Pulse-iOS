#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct HomeView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @State private var heroIndex = 0

    public init() {}

    private var heroVideo: Video? {
        guard case .loaded(let feed) = stores.home.state, feed.hero.indices.contains(heroIndex) else { return nil }
        return feed.hero[heroIndex]
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                content
            }
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background { backdrop }
        .overlay(alignment: .top) { header }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await stores.home.load(force: true) }
        .task { await stores.home.load() }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let hero = heroVideo { AmbientBackdrop(path: hero.poster ?? hero.thumb, seed: hero.id, strength: 0.5) }
        else { AuroraBackground() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            PulseMark(size: 17)
            Spacer()
            Button { player.tonightOpen = true } label: { Image(systemName: "sparkles").symbolEffect(.variableColor.iterative, options: .repeat(2)) }
                .buttonStyle(.pulseIcon)
                .accessibilityLabel("Tonight picks")
            Button { player.tab = .settings } label: { Image(systemName: "gearshape") }
                .buttonStyle(.pulseIcon)
                .accessibilityLabel("Settings")
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, 58)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            LinearGradient(colors: [Theme.bg.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom).frame(height: 150).ignoresSafeArea().allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stores.home.state {
        case .idle, .loading:
            HomeSkeleton()
        case .failed(let error):
            ErrorStateView(error.errorDescription ?? "Couldn't load your library.") { Task { await stores.home.load(force: true) } }
                .padding(.top, 120)
        case .loaded(let feed):
            if stores.home.libraryIsEmpty {
                EmptyStateView("Add your first library", message: "Connect pCloud or TorBox, choose your folders, and Pulse builds your library.",
                               systemImage: "externaldrive.badge.plus", actionTitle: "Add a library") { player.openLibraries() }
                    .padding(.top, 120)
            } else {
                if !feed.hero.isEmpty { HeroCarousel(videos: feed.hero, index: $heroIndex) }
                stats
                let rails = feed.rails.filter { !$0.items.isEmpty }
                let featuredID = rails.first { $0.kind == .scenes && $0.id != "continue" }?.id
                ForEach(rails) { rail in
                    RailView(rail: rail, style: style(for: rail, featuredID: featuredID))
                }
            }
        }
    }

    private func style(for rail: HomeRail, featuredID: String?) -> RailView.Style {
        if rail.id == "continue" { return .continueWatching }
        if rail.id == featuredID { return .featured }
        return .poster
    }

    @ViewBuilder
    private var stats: some View {
        if let facets = stores.library.facets {
            HStack(spacing: 10) {
                StatTile(value: facets.totals.scenes, label: "Videos", icon: "play.rectangle.fill")
                StatTile(value: facets.totals.matched, label: "Matched", icon: "checkmark.seal.fill")
                StatTile(value: facets.totals.favorites, label: "Favourites", icon: "heart.fill")
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
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.accent)
            CountUpText(value)
                .font(PulseFont.display(26, relativeTo: .title2, weight: .heavy))
                .foregroundStyle(Theme.text)
            Text(label).font(.caption.weight(.medium)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .pulseGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct RailView: View {
    enum Style { case poster, featured, continueWatching }

    let rail: HomeRail
    var style: Style = .poster
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(LocalizedStringKey(rail.title), action: seeAllAction)
            switch (rail.kind, style) {
            case (.performers, _):
                strip { ForEach(rail.performers) { PerformerBubble(performer: $0, diameter: 84).pulseScrollReveal() } }
            case (.scenes, .featured):
                curved
            case (.scenes, .continueWatching):
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: 280, showsPlay: true).pulseScrollReveal() } }
            case (.scenes, .poster):
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: 250).pulseScrollReveal() } }
            }
        }
    }

    private func strip<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Theme.Space.rail) { content() }
                .scrollTargetLayout()
                .padding(.horizontal, Theme.Space.page)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }

    /// Big portrait cards that swing on a Y axis as they pass the centre.
    private var curved: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 6) {
                ForEach(rail.scenes) { scene in
                    FeatureCard(scene: scene).pulseCurvedCarousel()
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
        }
        .contentMargins(.horizontal, (UIScreen.main.bounds.width - FeatureCard.size.width) / 2, for: .scrollContent)
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: FeatureCard.size.height + 36)
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
        VStack(alignment: .leading, spacing: 28) {
            Rectangle().fill(Theme.surface).frame(height: HeroCarousel.height).overlay { Shimmer() }
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.surface)
                            .frame(width: 250, height: 156).overlay { Shimmer() }.clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
                    }
                }
                .padding(.horizontal, Theme.Space.page)
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
