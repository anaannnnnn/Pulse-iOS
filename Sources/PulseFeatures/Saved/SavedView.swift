#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct SavedView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var section: SavedSection = .videos

    enum SavedSection: String, CaseIterable, Identifiable {
        case videos = "Videos", watchlist = "Watchlist", people = "People"
        var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PulseSegmented(selection: $section, options: SavedSection.allCases.map {
                    (value: $0, title: LocalizedStringKey($0.rawValue), icon: nil as String?)
                })
                .padding(.horizontal, Theme.Space.page)
                content
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await stores.favorites.load() }
        .task { await stores.favorites.load() }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private var content: some View {
        switch stores.favorites.state {
        case .idle, .loading:
            ProgressView().padding(.top, 80)
        case .failed(let error):
            ErrorStateView(error.errorDescription ?? "Couldn't load your saved items.") { Task { await stores.favorites.load() } }
        case .loaded(let bundle):
            switch section {
            case .videos:
                grid(bundle.scenes.filter { stores.hub.isFavorite($0) }, empty: ("No favourite videos", "Tap the heart on any video to keep it here.", "heart"))
            case .watchlist:
                grid(stores.favorites.watchlist.filter { stores.hub.isWatchlisted($0) }, empty: ("Watchlist is empty", "Bookmark videos you want to watch later.", "bookmark"))
            case .people:
                peopleContent(bundle)
            }
        }
    }

    @ViewBuilder
    private func grid(_ videos: [Video], empty: (LocalizedStringKey, LocalizedStringKey, String)) -> some View {
        if videos.isEmpty {
            EmptyStateView(empty.0, message: empty.1, systemImage: empty.2)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320), spacing: 14, alignment: .top)], spacing: 22) {
                ForEach(videos) { SceneCard(scene: $0) }
            }
            .padding(.horizontal, Theme.Space.page)
        }
    }

    @ViewBuilder
    private func peopleContent(_ bundle: FavoritesBundle) -> some View {
        let performers = bundle.performers.filter { stores.hub.isFavorite($0) }
        let studios = bundle.studios.filter { stores.hub.isFavorite($0) }
        if performers.isEmpty && studios.isEmpty {
            EmptyStateView("Nobody followed yet", message: "Follow performers and studios to see them here.", systemImage: "person.crop.circle.badge.plus")
        } else {
            VStack(alignment: .leading, spacing: 22) {
                if !performers.isEmpty {
                    SectionHeader("Performers")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 14)], spacing: 18) {
                        ForEach(performers) { PerformerCard(performer: $0) }
                    }
                    .padding(.horizontal, Theme.Space.page)
                }
                if !studios.isEmpty {
                    SectionHeader("Studios")
                    LazyVStack(spacing: 10) { ForEach(studios) { StudioCard(studio: $0) } }.padding(.horizontal, Theme.Space.page)
                }
            }
        }
    }
}
#endif
