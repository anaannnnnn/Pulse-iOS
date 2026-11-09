#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Search ThePornDB + StashDB for the right metadata and apply it.
struct MatchSearchSheet: View {
    let video: Video
    var onApplied: (SceneDetail) -> Void
    @State private var store: MatchSearchStore
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(video: Video, api: any PulseAPI, onApplied: @escaping (SceneDetail) -> Void) {
        self.video = video
        self.onApplied = onApplied
        _store = State(initialValue: MatchSearchStore(scene: video, api: api))
        _text = State(initialValue: video.title)
    }

    var body: some View {
        NavigationStack {
            List {
                if store.isSearching {
                    HStack { Spacer(); ProgressView("Searching…"); Spacer() }.listRowBackground(Color.clear)
                } else if store.candidates.isEmpty {
                    ContentUnavailableView("No matches yet", systemImage: "magnifyingglass",
                                           description: Text("Search by title, or try performer and studio names."))
                        .listRowBackground(Color.clear)
                }
                ForEach(store.candidates) { candidate in
                    CandidateRow(candidate: candidate) {
                        Task { if let detail = await store.apply(candidate) { onApplied(detail); dismiss() } }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Find match")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $text, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search title")
            .onSubmit(of: .search) { Task { await store.search(text) } }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task { await store.search(nil) }
            .overlay { if store.applying { ProgressView().controlSize(.large).padding(30).pulseGlass() } }
            .alert("Couldn't search", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(store.message ?? "") }
        }
        .presentationDetents([.large])
    }
}

private struct CandidateRow: View {
    let candidate: MatchCandidate
    let apply: () -> Void

    var body: some View {
        Button(action: apply) {
            HStack(spacing: 12) {
                PulseArt(candidate.poster, seed: candidate.tpdbId.hashValue & 0xFFFF)
                    .frame(width: 96, height: 60)
                    .clipShape(.rect(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(candidate.title).font(PulseFont.ui(.subheadline, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
                    Text([candidate.studio, candidate.date].compactMap { $0 }.joined(separator: " · "))
                        .font(PulseFont.ui(.caption)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    if !candidate.performers.isEmpty {
                        Text(candidate.performers.prefix(3).joined(separator: ", ")).font(PulseFont.ui(.caption2)).foregroundStyle(Theme.textTertiary).lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Chip(LocalizedStringKey((candidate.source ?? .tpdb).label))
                        if let by = candidate.matchedBy { Chip(LocalizedStringKey(by)) }
                    }
                }
                Spacer(minLength: 0)
                ZStack {
                    ProgressRing(candidate.confidence, lineWidth: 3)
                    Text(Format.percent(candidate.confidence)).font(PulseFont.timecode(.caption2)).foregroundStyle(Theme.text)
                }
                .frame(width: 44, height: 44)
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("\(candidate.title), \(Format.percent(candidate.confidence)) confidence")
        .accessibilityHint("Applies this match")
    }
}
#endif
