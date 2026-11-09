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
    @FocusState private var focused: Bool
    @State private var recents: [String] = UserDefaults.standard.stringArray(forKey: "pulse.recentSearches") ?? []

    public init() {}

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search").font(PulseFont.display(34, relativeTo: .largeTitle, weight: .heavy)).tracking(-0.6).foregroundStyle(Theme.text)
                    searchField
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.top, 8)
                if trimmed.isEmpty { recentsSection }
                else if videos.isEmpty && performers.isEmpty && studios.isEmpty && !searching {
                    EmptyStateView("No results", message: "Nothing matches “\(trimmed)”. Try a performer, studio or part of a title.", systemImage: "magnifyingglass")
                } else { results }
            }
            .padding(.bottom, 24)
            .animation(Theme.glide, value: trimmed.isEmpty)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { backdrop }
        .toolbar(.hidden, for: .navigationBar)
        .onSubmit(of: .text) { remember(trimmed) }
        .task(id: trimmed) { await run(trimmed) }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let first = videos.first, !trimmed.isEmpty { AmbientBackdrop(path: first.poster ?? first.thumb, seed: first.id, strength: 0.4) }
        else { AuroraBackground(intensity: 0.8) }
    }

    /// Large glass pill. Its rim lights up mint while typing.
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(focused ? Theme.accent : Theme.textSecondary)
                .symbolEffect(.bounce, value: focused)
            TextField("Videos, performers, studios", text: $text)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(Theme.text)
                .tint(Theme.accent)
                .focused($focused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if searching {
                ProgressView().tint(Theme.accent)
            } else if !text.isEmpty {
                Button { withAnimation(Theme.tap) { text = "" } } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(Theme.textSecondary)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 56)
        .background(Theme.raised, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.accent.opacity(focused ? 0.75 : 0), lineWidth: 1.5))
        .shadow(color: Theme.accent.opacity(focused ? 0.28 : 0), radius: 18)
        .animation(Theme.tap, value: focused)
    }

    @ViewBuilder
    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent").font(PulseFont.headline(.title2)).foregroundStyle(Theme.text)
                        Spacer()
                        Button("Clear") { recents = []; UserDefaults.standard.removeObject(forKey: "pulse.recentSearches") }
                            .font(.footnote.weight(.semibold)).foregroundStyle(Theme.accent)
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(recents, id: \.self) { term in
                            Button { text = term } label: {
                                Label(term, systemImage: "clock.arrow.circlepath").font(.footnote.weight(.semibold)).foregroundStyle(Theme.text)
                                    .padding(.horizontal, 12).frame(minHeight: 36).pulsePill()
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.page)
            }
            BrowseTiles()
        }
    }

    @ViewBuilder
    private var results: some View {
        if !performers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Performers", count: performers.count)
                ScrollView(.horizontal) {
                    HStack(spacing: 16) { ForEach(performers) { PerformerBubble(performer: $0, diameter: 84).pulseScrollReveal() } }.padding(.horizontal, Theme.Space.page)
                }
                .scrollIndicators(.hidden)
            }
        }
        if !studios.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Studios", count: studios.count)
                LazyVStack(spacing: 10) { ForEach(studios.prefix(4)) { StudioCard(studio: $0) } }.padding(.horizontal, Theme.Space.page)
            }
        }
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Videos", count: videos.count)
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
