#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct SceneDetailView: View {
    let video: Video
    @State private var store: SceneStore
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @State private var showEdit = false
    @State private var showMatch = false
    @State private var confirmUnmatch = false
    @State private var toast: String?

    init(video: Video, api: any PulseAPI) {
        self.video = video
        _store = State(initialValue: SceneStore(sceneID: video.id, api: api))
    }

    private var detail: SceneDetail? { store.state.value }
    private var current: Video { detail?.scene ?? video }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                VStack(alignment: .leading, spacing: 24) {
                    titleBlock
                    actions
                    if let text = detail?.description, !text.isEmpty { synopsis(text) }
                    glance
                    if let detail, !detail.performers.isEmpty { cast(detail.performers) }
                    if let detail, !detail.tags.isEmpty { tags(detail.tags) }
                    matching
                    fileInfo
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background { AmbientBackdrop(path: detail?.backdrop ?? current.poster ?? current.thumb, seed: current.id, strength: 0.45) }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { toolbarContent }
        .task { await store.load() }
        .sheet(isPresented: $showEdit) { if let detail { EditSceneSheet(store: store, detail: detail) } }
        .sheet(isPresented: $showMatch) { MatchSearchSheet(video: current, api: stores.api) { _ in Task { await store.load() } } }
        .confirmationDialog("Remove this match?", isPresented: $confirmUnmatch, titleVisibility: .visible) {
            Button("Unmatch", role: .destructive) { Task { await store.unmatch() } }
        } message: { Text("The video keeps its file name but loses artwork, cast and tags.") }
        .pulseToast($toast)
        .onChange(of: store.message) { _, message in if let message { toast = message; store.message = nil } }
    }

    // MARK: Sections

    private var hero: some View {
        Color.clear.frame(height: 520)
            .overlay { PulseArt(detail?.backdrop ?? current.poster ?? current.thumb, seed: current.id) }
            .overlay { Theme.scrim }
            .visualEffect { content, proxy in
                let minY = proxy.frame(in: .scrollView).minY
                return content.scaleEffect(minY > 0 ? 1 + minY / 600 : 1, anchor: .bottom).offset(y: minY > 0 ? -minY : 0)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(current.title)
                .font(PulseFont.display(.largeTitle, weight: .heavy))
                .tracking(-0.7)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                if let studio = current.studio {
                    NavigationLink(value: Route.studio(studio.id)) {
                        Label(studio.name, systemImage: "building.2").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    }
                }
                if let year = current.year { Text(String(year)).font(.subheadline).foregroundStyle(Theme.textSecondary) }
                if let runtime = Format.runtime(current.duration) { Text("· \(runtime)").font(.subheadline).foregroundStyle(Theme.textSecondary) }
            }
            if let badge = matchBadge { Chip(LocalizedStringKey(badge), systemImage: "checkmark.seal.fill", tint: Theme.success) }
        }
        .offset(y: -40)
        .padding(.bottom, -40)
    }

    private var matchBadge: String? {
        guard current.matchStatus.isResolved else { return nil }
        if current.matchStatus == .manual { return "Matched by hand" }
        return current.matchSource.map { "Matched via \($0.label)" } ?? "Matched"
    }

    private var actions: some View {
        PulseGlassGroup {
            HStack(spacing: 12) {
                Button { player.play(current) } label: {
                    Label(current.isInProgress ? "Resume" : "Play", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pulsePrimary)
                .sensoryFeedback(.impact(weight: .medium), trigger: player.scene?.id)

                Button { Task { await stores.hub.toggle(current) } } label: {
                    Image(systemName: stores.hub.isFavorite(current) ? "heart.fill" : "heart")
                        .symbolEffect(.bounce, value: stores.hub.isFavorite(current))
                }
                .buttonStyle(.pulseIcon(isOn: stores.hub.isFavorite(current), tint: Theme.ember))
                .accessibilityLabel(stores.hub.isFavorite(current) ? "Remove favourite" : "Add favourite")

                Button { Task { await stores.hub.toggle(current, list: .watchlist) } } label: {
                    Image(systemName: stores.hub.isWatchlisted(current) ? "bookmark.fill" : "bookmark")
                        .symbolEffect(.bounce, value: stores.hub.isWatchlisted(current))
                }
                .buttonStyle(.pulseIcon(isOn: stores.hub.isWatchlisted(current)))
                .accessibilityLabel(stores.hub.isWatchlisted(current) ? "Remove from watchlist" : "Add to watchlist")
            }
        }
        .sensoryFeedback(.selection, trigger: stores.hub.isFavorite(current))
    }

    private func synopsis(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            Text(text).font(.body).foregroundStyle(Theme.textSecondary).lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseGlass(in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var glance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("At a glance").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                GlanceTile(label: "Duration", value: Format.clock(current.duration), systemImage: "clock")
                GlanceTile(label: "Quality", value: [current.resolutionLabel, current.width.flatMap { w in current.height.map { "\(w)×\($0)" } }].compactMap { $0 }.first ?? "—", systemImage: "sparkles.tv")
                GlanceTile(label: "Size", value: Format.bytes(current.size), systemImage: "internaldrive")
                GlanceTile(label: "Released", value: current.date ?? "—", systemImage: "calendar")
                GlanceTile(label: "Source", value: current.source == .pcloud ? "pCloud" : "TorBox", systemImage: "icloud")
                if let progress = current.progress, progress.fraction > 0 {
                    GlanceTile(label: "Watched", value: Format.percent(progress.fraction), systemImage: "eye")
                }
            }
        }
    }

    private func cast(_ performers: [Performer]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cast").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            ScrollView(.horizontal) {
                HStack(spacing: 16) { ForEach(performers) { PerformerBubble(performer: $0) } }.padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func tags(_ tags: [Tag]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    NavigationLink(value: Route.filtered(title: tag.name, query: tagQuery(tag))) {
                        Text(tag.name).font(.footnote.weight(.semibold)).foregroundStyle(Theme.text)
                            .padding(.horizontal, 12).frame(minHeight: 34).pulseCapsuleGlass()
                    }
                }
            }
        }
    }

    private func tagQuery(_ tag: Tag) -> LibraryQuery { var q = LibraryQuery(); q.tagIDs = [tag.id]; return q }

    private var matching: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            VStack(spacing: 0) {
                MetaRow(label: "Status", value: current.matchStatus.rawValue.capitalized)
                if let c = current.matchConfidence { MetaRow(label: "Confidence", value: Format.percent(c)) }
                if let ext = detail?.tpdb?.url, let url = URL(string: ext) { LinkRow(label: "ThePornDB", url: url) }
                if let ext = detail?.stashdb?.url, let url = URL(string: ext) { LinkRow(label: "StashDB", url: url) }
            }
            .pulseGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            HStack(spacing: 10) {
                Button("Find match", systemImage: "magnifyingglass") { showMatch = true }.buttonStyle(.pulseGlass)
                Button("Edit", systemImage: "pencil") { showEdit = true }.buttonStyle(.pulseGlass)
                if current.matchStatus.isResolved {
                    Button("Unmatch", systemImage: "link.badge.plus") { confirmUnmatch = true }.buttonStyle(.pulseGlass(tint: Theme.danger))
                }
            }
            .font(.subheadline)
        }
    }

    private var fileInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            Text(current.path).font(.caption.monospaced()).foregroundStyle(Theme.textTertiary).textSelection(.enabled)
            if current.progress != nil {
                Button("Clear watch progress", systemImage: "arrow.counterclockwise") { Task { await store.clearProgress() } }
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ShareLink(item: current.title) { Image(systemName: "square.and.arrow.up") }
        }
    }
}

private struct GlanceTile: View {
    let label: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).font(.title3).foregroundStyle(Theme.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                Text(value).font(PulseFont.label(.subheadline)).fontWeight(.semibold).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .pulseGlass(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct MetaRow: View {
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.text).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, 16).frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

struct LinkRow: View {
    let label: LocalizedStringKey
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                Text(label).foregroundStyle(Theme.textSecondary)
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(Theme.accentSoft)
            }
            .font(.subheadline)
            .padding(.horizontal, 16).frame(minHeight: 44)
        }
    }
}
#endif
