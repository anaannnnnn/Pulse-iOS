#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Bulk matching dashboard plus the review queue of files that still need a decision.
struct MatchingView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var reviewing: Video?

    var body: some View {
        let store = stores.matching
        SettingsForm(title: "Matching & review") {
            Section("Progress") {
                jobCard(store.job)
                HStack(spacing: 10) {
                    Button("Match all unmatched", systemImage: "wand.and.stars") {
                        Task { await store.run(.queue(sceneIDs: nil, all: true, priority: false)) }
                    }
                    .disabled(store.job.state == .running && !store.job.paused)
                }
                if store.job.state == .running {
                    HStack {
                        if store.job.paused {
                            Button("Resume", systemImage: "play.fill") { Task { await store.run(.resume) } }
                        } else {
                            Button("Pause", systemImage: "pause.fill") { Task { await store.run(.pause) } }
                        }
                        Spacer()
                        Button("Cancel", systemImage: "xmark", role: .destructive) { Task { await store.run(.cancel) } }
                    }
                    .buttonStyle(.borderless)
                }
                Button("Retry everything that failed", systemImage: "arrow.counterclockwise") { Task { await store.run(.retryUnmatched) } }
            }
            Section {
                if store.unmatched.isEmpty {
                    Label("Nothing needs review", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.success)
                }
                ForEach(store.unmatched) { video in
                    Button { reviewing = video } label: {
                        HStack(spacing: 12) {
                            PulseArt(video.poster ?? video.thumb, seed: video.id).frame(width: 84, height: 52).clipShape(.rect(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(video.title).font(PulseFont.ui(.subheadline, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
                                Text(video.matchStatus.rawValue.capitalized).font(PulseFont.ui(.caption)).foregroundStyle(Theme.warning)
                            }
                        }
                    }
                    .swipeActions { Button("Ignore", systemImage: "eye.slash") { Task { await store.ignore(video) } }.tint(.gray) }
                }
            } header: { Text("Needs review · \(store.unmatched.count)") }
        }
        .task { await store.load() }
        .onDisappear { store.stopPolling() }
        .sheet(item: $reviewing) { video in
            MatchSearchSheet(video: video, api: stores.api) { _ in Task { await store.load() } }
        }
    }

    @ViewBuilder
    private func jobCard(_ job: MatchJobStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(job.state == .running ? (job.paused ? "Paused" : "Matching…") : "Idle").font(PulseFont.headline(.title3))
                Spacer()
                if job.state == .running, job.rate > 0 { Text("\(Int(job.rate))/min").font(PulseFont.timecode(.caption)).foregroundStyle(Theme.textSecondary) }
            }
            if job.state == .running {
                ProgressView(value: job.fraction).tint(Theme.accent)
                if let current = job.current { Text(current.title).font(PulseFont.ui(.caption)).foregroundStyle(Theme.textSecondary).lineLimit(1) }
                if let eta = Format.eta(job.etaSeconds) { Text("About \(eta) left").font(PulseFont.ui(.caption)).foregroundStyle(Theme.textSecondary) }
            }
            HStack(spacing: 18) {
                stat(job.matched, "Matched", Theme.success)
                stat(job.unmatched, "Unmatched", Theme.warning)
                stat(job.failed, "Failed", Theme.danger)
                stat(job.queued, "Queued", Theme.textSecondary)
            }
            if let error = job.lastError { Text(error).font(PulseFont.ui(.caption)).foregroundStyle(Theme.danger) }
        }
        .padding(.vertical, 4)
    }

    private func stat(_ value: Int, _ label: LocalizedStringKey, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number).font(PulseFont.timecode(.headline)).foregroundStyle(color).contentTransition(.numericText())
            Text(label).font(PulseFont.ui(.caption2)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct SourcesSettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var testing: MetadataProvider?

    var body: some View {
        @Bindable var settings = stores.settings
        SettingsForm(title: "Metadata sources") {
            Section {
                provider(.tpdb, enabled: $settings.settings.metadata.tpdb)
                provider(.stashdb, enabled: $settings.settings.metadata.stashdb)
            } footer: {
                Text("Pulse searches both at once and keeps the best match. API keys live in your server's settings file, never on this phone.")
            }
        }
        .onChange(of: settings.settings.metadata) { _, _ in settings.scheduleSave() }
        .task { await stores.settings.load(); await stores.matching.load() }
    }

    @ViewBuilder
    private func provider(_ provider: MetadataProvider, enabled: Binding<Bool>) -> some View {
        let source = stores.matching.sources.first { $0.id == provider }
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: enabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.label).font(PulseFont.headline(.title3))
                    Text(source?.configured == true ? "Key configured" : "No key on the server")
                        .font(PulseFont.ui(.caption)).foregroundStyle(source?.configured == true ? Theme.success : Theme.warning)
                }
            }
            .disabled(source?.configured != true)
            HStack {
                Button { Task { testing = provider; await stores.matching.test(provider); testing = nil } } label: {
                    if testing == provider { ProgressView() } else { Label("Test connection", systemImage: "network") }
                }
                .buttonStyle(.borderless)
                if let result = stores.matching.tests[provider] {
                    Label(result.ok ? "Working" : (result.hint ?? "Failed"), systemImage: result.ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .font(PulseFont.ui(.caption)).foregroundStyle(result.ok ? Theme.success : Theme.danger).lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DataSettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var pending: ClearDataScope?
    @State private var toast: String?

    var body: some View {
        SettingsForm(title: "Data & storage") {
            Section {
                ForEach([ClearDataScope.progress, .cache, .favorites, .metadata]) { scope in
                    Button(scope.label, role: .destructive) { pending = scope }
                }
            } header: { Text("Clear") } footer: { Text("These actions happen on your server and affect every device.") }
            Section {
                Button(ClearDataScope.library.label, role: .destructive) { pending = .library }
                Button(ClearDataScope.all.label, role: .destructive) { pending = .all }
            } header: { Text("Danger zone") } footer: { Text("Your files in pCloud and TorBox are never deleted.") }
        }
        .confirmationDialog("Clear \(pending?.label.lowercased() ?? "")?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                if let scope = pending { Task { await stores.settings.clear(scope); toast = stores.settings.message } }
                pending = nil
            }
        } message: { Text("This can't be undone.") }
        .pulseToast($toast)
    }
}

struct AboutView: View {
    @Environment(AppSession.self) private var session
    @State private var health: HealthInfo?

    var body: some View {
        SettingsForm(title: "About") {
            Section {
                VStack(spacing: 12) {
                    PulseMark(size: 40)
                    Text("A private streaming app for your own library.").font(PulseFont.ui(.footnote)).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            Section {
                LabeledContent("App version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
                LabeledContent("Server", value: session.isDemo ? "Demo" : (session.serverURL.absoluteString))
                LabeledContent("Server version", value: health?.version ?? "—")
            }
        }
        .task { health = try? await session.api.health() }
    }
}
#endif
