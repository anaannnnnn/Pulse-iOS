#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct PerformerDetailView: View {
    @State private var store: PerformerStore
    @Environment(StoreBundle.self) private var stores
    @State private var toast: String?

    init(id: Int, api: any PulseAPI) { _store = State(initialValue: PerformerStore(performerID: id, api: api)) }

    var body: some View {
        ScrollView {
            switch store.state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity).padding(.top, 120)
            case .failed(let error):
                ErrorStateView(error.errorDescription ?? "Couldn't load this profile.") { Task { await store.load() } }
            case .loaded(let detail):
                content(detail)
            }
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.7)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let performer = store.state.value?.performer {
                    Menu {
                        Button("Refresh from ThePornDB", systemImage: "arrow.clockwise") { Task { await store.refresh(from: .tpdb) } }
                        Button("Refresh from StashDB", systemImage: "arrow.clockwise") { Task { await store.refresh(from: .stashdb) } }
                    } label: {
                        if store.refreshing { ProgressView() } else { Image(systemName: "ellipsis.circle") }
                    }
                    .accessibilityLabel("More for \(performer.name)")
                }
            }
        }
        .task { await store.load() }
        .pulseToast($toast)
        .onChange(of: store.message) { _, m in if let m { toast = m; store.message = nil } }
    }

    private func content(_ detail: PerformerDetail) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(spacing: 14) {
                PulseArt(detail.performer.image ?? detail.performer.thumb, seed: detail.id)
                    .frame(width: 156, height: 156)
                    .clipShape(Circle())
                    .padding(5)
                    .background(Circle().strokeBorder(Theme.gradient, lineWidth: 3))
                    .shadow(color: Theme.accent.opacity(0.4), radius: 24, y: 10)
                Text(detail.performer.name).font(PulseFont.display(.title2)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                if !detail.aliases.isEmpty {
                    Text("aka " + detail.aliases.prefix(3).joined(separator: ", ")).font(.footnote).foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 8) {
                    Chip("\(detail.scenes.count) scenes", systemImage: "play.rectangle")
                    if let source = detail.performer.source { Chip(LocalizedStringKey(source.label), systemImage: "checkmark.seal") }
                }
                Button {
                    Task { await stores.hub.toggle(detail.performer) }
                } label: {
                    Label(stores.hub.isFavorite(detail.performer) ? "Following" : "Follow",
                          systemImage: stores.hub.isFavorite(detail.performer) ? "heart.fill" : "heart")
                        .symbolEffect(.bounce, value: stores.hub.isFavorite(detail.performer))
                }
                .buttonStyle(.pulseGlass(tint: stores.hub.isFavorite(detail.performer) ? Theme.accent : nil))
                .sensoryFeedback(.success, trigger: stores.hub.isFavorite(detail.performer))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)

            if let bio = detail.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
                    Text(bio).font(.body).foregroundStyle(Theme.textSecondary).lineSpacing(3)
                }
                .padding(.horizontal, Theme.Space.page)
            }

            if !detail.facts.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(detail.facts.enumerated()), id: \.offset) { _, fact in
                        MetaRow(label: LocalizedStringKey(fact.label), value: fact.value)
                    }
                }
                .background(Theme.surface.opacity(0.7), in: .rect(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, Theme.Space.page)
            }

            if detail.images.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(detail.images, id: \.self) { image in
                            PulseArt(image, seed: detail.id).frame(width: 130, height: 170).clipShape(.rect(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, Theme.Space.page)
                }
                .scrollIndicators(.hidden)
            }

            if !detail.scenes.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader("Scenes", subtitle: "\(detail.scenes.count) in your library")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320), spacing: 14, alignment: .top)], spacing: 22) {
                        ForEach(detail.scenes) { SceneCard(scene: $0) }
                    }
                    .padding(.horizontal, Theme.Space.page)
                }
            }

            if !detail.links.isEmpty {
                VStack(spacing: 0) {
                    ForEach(detail.links.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        if let url = URL(string: value) { LinkRow(label: LocalizedStringKey(key), url: url) }
                    }
                }
                .background(Theme.surface.opacity(0.7), in: .rect(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, Theme.Space.page)
            }
        }
        .padding(.bottom, 24)
    }
}

struct StudioDetailView: View {
    @State private var store: StudioStore
    @Environment(StoreBundle.self) private var stores

    init(id: Int, api: any PulseAPI) { _store = State(initialValue: StudioStore(studioID: id, api: api)) }

    var body: some View {
        ScrollView {
            switch store.state {
            case .idle, .loading: ProgressView().frame(maxWidth: .infinity).padding(.top, 120)
            case .failed(let e): ErrorStateView(e.errorDescription ?? "Couldn't load this studio.") { Task { await store.load() } }
            case .loaded(let detail):
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(detail.studio.name).font(PulseFont.display(.title)).foregroundStyle(Theme.text)
                        if let parent = detail.studio.parent { Text(parent).font(.subheadline).foregroundStyle(Theme.textSecondary) }
                        HStack {
                            Chip("\(detail.scenes.count) scenes", systemImage: "play.rectangle")
                            Button {
                                Task { await stores.hub.toggle(detail.studio) }
                            } label: {
                                Label(stores.hub.isFavorite(detail.studio) ? "Following" : "Follow",
                                      systemImage: stores.hub.isFavorite(detail.studio) ? "heart.fill" : "heart")
                            }
                            .buttonStyle(.pulseGlass(tint: stores.hub.isFavorite(detail.studio) ? Theme.accent : nil))
                        }
                    }
                    .padding(.horizontal, Theme.Space.page)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320), spacing: 14, alignment: .top)], spacing: 22) {
                        ForEach(detail.scenes) { SceneCard(scene: $0) }
                    }
                    .padding(.horizontal, Theme.Space.page)
                }
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.6)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.load() }
    }
}

/// Library results for a route-supplied query (tag chips, "see all").
struct FilteredLibraryView: View {
    let title: String
    @State private var store: LibraryStore

    init(title: String, query: LibraryQuery, api: any PulseAPI) {
        self.title = title
        _store = State(initialValue: LibraryStore(api: api, initial: query))
    }

    var body: some View {
        ScrollView {
            if store.scenes.isEmpty && !store.isLoading {
                EmptyStateView("Nothing here yet", message: "No videos match this filter.", systemImage: "tray")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 320), spacing: 14, alignment: .top)], spacing: 22) {
                ForEach(store.scenes) { video in
                    SceneCard(scene: video).task { await store.loadMoreIfNeeded(current: video) }
                }
            }
            .padding(Theme.Space.page)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task { await store.reload() }
    }
}
#endif
