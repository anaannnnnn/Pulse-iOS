#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct HomeView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @State private var heroIndex = 0
    @State private var size = CGSize(width: 390, height: 844)

    public init() {}

    /// Card width scales with the screen so layouts hold from iPhone SE to Pro Max.
    private var cardWidth: CGFloat { min(max(size.width * 0.58, 200), 300).rounded() }
    /// Tall poster width: about 2.6 across.
    private var posterWidth: CGFloat { min(max(size.width * 0.34, 118), 170).rounded() }
    /// Portrait-ish on phones, capped by the screen height so the first rail always peeks in.
    private var heroHeight: CGFloat { min(max(size.width * 1.28, 340), max(size.height * 0.68, 340), 640).rounded() }

    private var heroVideo: Video? {
        guard case .loaded(let feed) = stores.home.state, feed.hero.indices.contains(heroIndex) else { return nil }
        return feed.hero[heroIndex]
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .background { backdrop }
        .overlay(alignment: .top) { header }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await stores.home.load(force: true) }
        .task { await stores.home.load() }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private var backdrop: some View {
        Theme.bg
    }

    private var header: some View {
        HStack(spacing: 10) {
            PulseMark(size: 15)
            Spacer()
            PulseGlassGroup(spacing: 10) {
                HStack(spacing: 10) {
                    Button { player.tonightOpen = true } label: { Image(systemName: "sparkles").symbolEffect(.variableColor.iterative, options: .repeat(2)) }
                        .buttonStyle(.pulseIcon)
                        .accessibilityLabel("Tonight picks")
                    Button { player.settingsOpen = true } label: { Image(systemName: "gearshape") }
                        .buttonStyle(.pulseIcon)
                        .accessibilityLabel("Settings")
                }
            }
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, DeviceInsets.top + 4)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            LinearGradient(colors: [Color.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom).frame(height: DeviceInsets.top + 90).ignoresSafeArea().allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stores.home.state {
        case .idle, .loading:
            HomeSkeleton(heroHeight: heroHeight)
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
                ForEach(rails) { rail in
                    RailView(rail: rail, style: style(for: rail, featuredID: featuredID), cardWidth: cardWidth, posterWidth: posterWidth)
                }
            }
        }
    }

    private func style(for rail: HomeRail, featuredID: String?) -> RailView.Style {
        if rail.id == "continue" { return .continueWatching }
        if rail.id == featuredID { return .featured }
        return .poster
    }

    /// Library readout: three counters in monospaced digits on a hairline slate.
    @ViewBuilder
    private var metrics: some View {
        if let facets = stores.library.facets {
            HStack(spacing: 0) {
                metric(facets.totals.scenes, "Videos")
                Rectangle().fill(Theme.lineStrong).frame(width: 1, height: 28)
                metric(facets.totals.matched, "Matched")
                Rectangle().fill(Theme.lineStrong).frame(width: 1, height: 28)
                metric(facets.totals.favorites, "Favourites")
            }
            .padding(.vertical, 14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous).strokeBorder(Theme.line, lineWidth: 1))
            .padding(.horizontal, Theme.Space.page)
        } else {
            Color.clear.frame(height: 0).task { await stores.library.loadFacets() }
        }
    }

    private func metric(_ value: Int, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            CountUpText(value, compact: true)
                .font(PulseFont.timecode(.title2))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
            Text(label).font(PulseFont.ui(.caption)).foregroundStyle(Theme.textSecondary).lineLimit(1)
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
    var posterWidth: CGFloat = 120
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(LocalizedStringKey(rail.title), action: seeAllAction).padding(.horizontal, Theme.Space.page)
            switch (rail.kind, style) {
            case (.performers, _):
                strip { ForEach(rail.performers) { PerformerBubble(performer: $0, diameter: 84).pulseScrollReveal() } }
            case (.scenes, .featured):
                top10
            case (.scenes, .continueWatching):
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: cardWidth, showsPlay: true).pulseScrollReveal() } }
            case (.scenes, .poster):
                strip { ForEach(rail.scenes) { SceneCard(scene: $0, width: posterWidth, portrait: true) } }
            }
        }
    }

    private func strip<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 8) { content() }
                .scrollTargetLayout()
                .padding(.horizontal, Theme.Space.page)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }

    /// Numbered "Top 10" strip.
    private var top10: some View {
        strip {
            ForEach(Array(rail.scenes.prefix(10).enumerated()), id: \.element.id) { i, scene in
                FeatureCard(scene: scene, rank: i + 1, posterWidth: posterWidth)
            }
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
    var heroHeight: CGFloat = 480

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Rectangle().fill(Theme.surface).frame(height: heroHeight).overlay { Shimmer() }
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.surface)
                            .aspectRatio(2 / 3, contentMode: .fit).frame(width: 120).overlay { Shimmer() }.clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
                    }
                }
                .padding(.horizontal, Theme.Space.page)
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
