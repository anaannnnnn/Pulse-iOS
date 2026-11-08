#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct HomeView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var heroIndex = 0
    @State private var size = CGSize(width: 390, height: 844)

    public init() {}

    /// Card width scales with the screen so layouts hold from iPhone SE to Pro Max.
    private var cardWidth: CGFloat { min(max(size.width * 0.62, 220), 340).rounded() }
    private var heroHeight: CGFloat {
        min(max(size.height * 0.56, 420), 600).rounded() + (dynamicTypeSize.isAccessibilitySize ? 120 : 0)
    }

    private var heroVideo: Video? {
        guard case .loaded(let feed) = stores.home.state, feed.hero.indices.contains(heroIndex) else { return nil }
        return feed.hero[heroIndex]
    }

    public var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Space.section) {
                    content
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .refreshable { await stores.home.load(force: true) }
            header
        }
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .background { backdrop }
        .toolbar(.hidden, for: .navigationBar)
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
            Button { player.settingsOpen = true } label: { Image(systemName: "gearshape") }
                .buttonStyle(.pulseIcon)
                .accessibilityLabel("Settings")
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, 8)
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
                if !feed.hero.isEmpty { HeroCarousel(videos: feed.hero, height: heroHeight, index: $heroIndex) }
                metrics
                let rails = feed.rails.filter { !$0.items.isEmpty }
                let featuredID = rails.first { $0.kind == .scenes && $0.id != "continue" }?.id
                ForEach(Array(rails.enumerated()), id: \.element.id) { index, rail in
                    RailView(rail: rail, style: style(for: rail, featuredID: featuredID), cardWidth: cardWidth, screenWidth: size.width)
                        .pulseScrollReveal(delay: Double(min(index, 3)) * 0.06)
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
    private var metrics: some View {
        if let facets = stores.library.facets {
            HStack(spacing: 0) {
                metric(facets.totals.scenes, "Videos")
                Divider().frame(height: 32).overlay(Theme.lineStrong)
                metric(facets.totals.matched, "Matched")
                Divider().frame(height: 32).overlay(Theme.lineStrong)
                metric(facets.totals.favorites, "Favourites")
            }
            .padding(.vertical, 16)
            .pulseGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .padding(.horizontal, Theme.Space.page)
        } else {
            Color.clear.frame(height: 0).task { await stores.library.loadFacets() }
        }
    }

    private func metric(_ value: Int, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            CountUpText(value, compact: true)
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.text)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct RailView: View {
    enum Style { case poster, featured, continueWatching }

    let rail: HomeRail
    var style: Style = .poster
    var cardWidth: CGFloat = 250
    var screenWidth: CGFloat = 390
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
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: cardWidth * 1.1, showsPlay: true).pulseScrollReveal() } }
            case (.scenes, .poster):
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: cardWidth).pulseScrollReveal() } }
            }
        }
    }

    private var featureWidth: CGFloat { (cardWidth * 1.1).rounded() }

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
            LazyHStack(spacing: 4) {
                ForEach(rail.scenes) { scene in
                    FeatureCard(scene: scene, width: featureWidth).pulseCurvedCarousel()
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
        }
        .contentMargins(.horizontal, (screenWidth - featureWidth) / 2, for: .scrollContent)
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: (featureWidth * 1.38).rounded() + 32)
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
            Rectangle().fill(Theme.surface).frame(height: 480).overlay { Shimmer() }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading library")
    }
}
#endif
