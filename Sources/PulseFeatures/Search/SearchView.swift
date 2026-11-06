#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Global search across videos, performers and studios.
public struct SearchView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var text = ""
    @State private var videos: [Video] = []
    @State private var performers: [Performer] = []
    @State private var studios: [Studio] = []
    @State private var searching = false
    @State private var recents: [String] = UserDefaults.standard.stringArray(forKey: "pulse.recentSearches") ?? []

    public init() {}

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if trimmed.isEmpty { recentsSection }
                else if videos.isEmpty && performers.isEmpty && studios.isEmpty && !searching {
                    EmptyStateView("No results", message: "Nothing matches “\(trimmed)”. Try a performer, studio or part of a title.", systemImage: "magnifyingglass")
                } else { results }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("Search")
        .searchable(text: $text, prompt: "Videos, performers, studios")
        .onSubmit(of: .search) { remember(trimmed) }
        .task(id: trimmed) { await run(trimmed) }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private var recentsSection: some View {
        if recents.isEmpty {
            EmptyStateView("Search your library", message: "Find videos by title, cast, studio or tag.", systemImage: "magnifyingglass")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recent").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
                    Spacer()
                    Button("Clear") { recents = []; UserDefaults.standard.removeObject(forKey: "pulse.recentSearches") }
                        .font(.footnote).foregroundStyle(Theme.accentSoft)
                }
                FlowLayout(spacing: 8) {
                    ForEach(recents, id: \.self) { term in
                        Button { text = term } label: {
                            Label(term, systemImage: "clock.arrow.circlepath").font(.footnote.weight(.semibold)).foregroundStyle(Theme.text)
                                .padding(.horizontal, 12).frame(minHeight: 36).pulseCapsuleGlass()
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.page)
        }
    }

    @ViewBuilder
    private var results: some View {
        if !performers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Performers")
                ScrollView(.horizontal) {
                    HStack(spacing: 16) { ForEach(performers) { PerformerBubble(performer: $0) } }.padding(.horizontal, Theme.Space.page)
                }
                .scrollIndicators(.hidden)
            }
        }
        if !studios.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Studios")
                LazyVStack(spacing: 10) { ForEach(studios.prefix(4)) { StudioCard(studio: $0) } }.padding(.horizontal, Theme.Space.page)
            }
        }
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Videos")
                LazyVStack(spacing: 10) { ForEach(videos) { SceneRow(scene: $0) } }.padding(.horizontal, Theme.Space.page)
            }
        }
    }

    private func run(_ term: String) async {
        guard !term.isEmpty else { videos = []; performers = []; studios = []; return }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        searching = true
        defer { searching = false }
        var vq = LibraryQuery(); vq.text = term; vq.pageSize = 20
        var pq = PerformerQuery(); pq.text = term; pq.pageSize = 12
        let api = stores.api
        async let v = try? api.library(vq)
        async let p = try? api.performers(pq)
        async let s = try? api.studios(query: term, favorites: false, page: 1)
        let (vr, pr, sr) = await (v, p, s)
        guard !Task.isCancelled else { return }
        videos = vr?.items ?? []
        performers = pr?.items ?? []
        studios = sr?.items ?? []
    }

    private func remember(_ term: String) {
        guard !term.isEmpty else { return }
        recents.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        recents.insert(term, at: 0)
        recents = Array(recents.prefix(10))
        UserDefaults.standard.set(recents, forKey: "pulse.recentSearches")
    }
}
#endif
