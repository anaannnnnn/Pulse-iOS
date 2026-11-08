#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct LibraryView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var showFilters = false
    @State private var layoutIsGrid = true

    public init() {}

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 320), spacing: 14, alignment: .top)]

    public var body: some View {
        @Bindable var library = stores.library
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if library.query.activeFilterCount > 0 { activeFilters }
                summary
                results
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $library.query.text, placement: .navigationBarDrawer(displayMode: .always), prompt: "Title, performer, studio, tag")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $library.query.sort) {
                        ForEach(LibrarySort.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Ascending", isOn: $library.query.ascending)
                    Divider()
                    Picker("Layout", selection: $layoutIsGrid) {
                        Label("Grid", systemImage: "square.grid.2x2").tag(true)
                        Label("List", systemImage: "list.bullet").tag(false)
                    }
                } label: { Label("Sort and layout", systemImage: "arrow.up.arrow.down") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFilters = true } label: {
                    Label("Filters", systemImage: library.query.activeFilterCount > 0
                          ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .badge(library.query.activeFilterCount)
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(query: $library.query).presentationDetents([.medium, .large]).presentationBackground(.ultraThinMaterial)
        }
        .task { await stores.library.reload(); await stores.library.loadFacets() }
        .refreshable { await stores.library.reload() }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    private var summary: some View {
        HStack {
            Text("\(stores.library.total) videos")
                .font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText())
                .animation(.smooth, value: stores.library.total)
            Spacer()
            if stores.library.isLoading { ProgressView().controlSize(.small) }
        }
    }

    @ViewBuilder
    private var results: some View {
        if let error = stores.library.error, stores.library.scenes.isEmpty {
            ErrorStateView(error.errorDescription ?? "Couldn't load videos.") { Task { await stores.library.reload() } }
        } else if stores.library.scenes.isEmpty && !stores.library.isLoading {
            EmptyStateView("No videos found", message: "Try a different search or clear your filters.", systemImage: "magnifyingglass",
                           actionTitle: stores.library.query.activeFilterCount > 0 ? "Clear filters" : nil) {
                stores.library.query.clearFilters()
            }
        } else if layoutIsGrid {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(stores.library.scenes) { video in
                    SceneCard(scene: video)
                        .task { await stores.library.loadMoreIfNeeded(current: video) }
                }
            }
            loadMoreFooter
        } else {
            LazyVStack(spacing: 10) {
                ForEach(stores.library.scenes) { video in
                    SceneRow(scene: video).task { await stores.library.loadMoreIfNeeded(current: video) }
                }
            }
            loadMoreFooter
        }
    }

    @ViewBuilder
    private var loadMoreFooter: some View {
        if stores.library.isLoadingMore { ProgressView().frame(maxWidth: .infinity).padding() }
    }

    private var activeFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                let q = stores.library.query
                if q.favoritesOnly { removable("Favourites") { stores.library.query.favoritesOnly = false } }
                if q.watchlistOnly { removable("Watchlist") { stores.library.query.watchlistOnly = false } }
                if q.watched != .any { removable(q.watched.label) { stores.library.query.watched = .any } }
                if q.yearFrom != nil || q.yearTo != nil {
                    removable("\(q.yearFrom.map(String.init) ?? "…")–\(q.yearTo.map(String.init) ?? "…")") {
                        stores.library.query.yearFrom = nil; stores.library.query.yearTo = nil
                    }
                }
                if q.minDuration != nil || q.maxDuration != nil {
                    removable("Length") { stores.library.query.minDuration = nil; stores.library.query.maxDuration = nil }
                }
                if !q.tagIDs.isEmpty { removable("\(q.tagIDs.count) tags") { stores.library.query.tagIDs = [] } }
                if !q.performerIDs.isEmpty { removable("\(q.performerIDs.count) performers") { stores.library.query.performerIDs = [] } }
                if !q.studioIDs.isEmpty { removable("\(q.studioIDs.count) studios") { stores.library.query.studioIDs = [] } }
                if let m = q.matched { removable(m ? "Matched" : "Unmatched") { stores.library.query.matched = nil } }
                if let s = q.source { removable(s == .pcloud ? "pCloud" : "TorBox") { stores.library.query.source = nil } }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func removable(_ title: String, remove: @escaping () -> Void) -> some View {
        Button(action: remove) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "xmark").font(.caption2.weight(.bold))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12).frame(minHeight: 34)
            .pulseCapsuleGlass(tint: Theme.accent.opacity(0.4))
        }
        .accessibilityLabel("Remove filter \(title)")
    }
}
#endif
