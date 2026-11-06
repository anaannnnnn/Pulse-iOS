#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Add and manage the platforms Pulse builds your library from.
struct LibrariesView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var settings = stores.settings
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                summary
                VStack(spacing: 14) {
                    pcloudCard
                    torboxCard
                }
                behaviour(settings: $settings.settings.library)
            }
            .padding(Theme.Space.page)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("Libraries")
        .navigationBarTitleDisplayMode(.large)
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await reload() } } }
        .onChange(of: settings.settings.library) { _, _ in settings.scheduleSave() }
    }

    private func reload() async {
        await stores.pcloud.load()
        await stores.torbox.load()
        await stores.settings.load()
        await stores.library.loadFacets()
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Where your videos come from").font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
            Text("Connect each platform once. Pulse scans the folders you pick, matches artwork and details, and keeps everything in one library.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
            if let totals = stores.library.facets?.totals {
                HStack(spacing: 8) {
                    Chip("\(totals.scenes) videos", systemImage: "play.rectangle")
                    Chip("\(totals.matched) matched", systemImage: "checkmark.seal")
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: Platform cards

    private var pcloudCard: some View {
        let store = stores.pcloud
        let connected = store.status?.connected == true
        return PlatformCard(
            title: "pCloud", systemImage: "icloud.fill", tint: Color(hex: 0x17BED0),
            connected: connected,
            detail: connected ? (store.status?.email ?? "Connected") : "Stream and scan videos stored in your pCloud.",
            route: .settings(.pcloud)
        ) {
            if connected {
                if let quota = store.status?.quota, quota > 0 {
                    ProgressView(value: store.status?.usedFraction ?? 0).tint(Color(hex: 0x17BED0))
                    Text("\(Format.bytes(Int64(store.status?.usedQuota ?? 0))) of \(Format.bytes(Int64(quota))) used")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Label(store.folders.isEmpty ? "Whole account" : "\(store.folders.count) folders", systemImage: "folder.fill")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                if store.scan.state == .running {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Scanning · \(store.scan.videosFound) videos found").font(.caption.monospacedDigit()).foregroundStyle(Theme.accentSoft)
                    }
                }
            }
        }
    }

    private var torboxCard: some View {
        let store = stores.torbox
        let linked = store.status?.linked == true
        return PlatformCard(
            title: "TorBox", systemImage: "arrow.down.circle.fill", tint: Color(hex: 0x4ADE80),
            connected: linked,
            detail: linked ? (store.status?.planName.map { "\($0) plan" } ?? "Linked") : "Stream cached torrents and add them to your library.",
            route: .settings(.torbox)
        ) {
            if linked {
                let ready = store.items.filter(\.ready).count
                Label("\(store.items.count) downloads · \(ready) ready", systemImage: "arrow.down.to.line")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: Behaviour

    private func behaviour(settings: Binding<LibrarySettings>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keeping it up to date").font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
            VStack(spacing: 0) {
                Toggle("Match new videos automatically", isOn: settings.autoMatch).padding(.horizontal, 16).frame(minHeight: 52)
                Divider().overlay(Theme.line)
                Picker("Scan for new videos", selection: settings.scanIntervalHours) {
                    Text("Only when I tap Scan").tag(0)
                    Text("Every hour").tag(1)
                    Text("Every 6 hours").tag(6)
                    Text("Every day").tag(24)
                }
                .padding(.horizontal, 16).frame(minHeight: 52)
                Divider().overlay(Theme.line)
                HStack {
                    Text("Match strictness")
                    Spacer()
                    Text(Format.percent(settings.wrappedValue.matchThreshold)).foregroundStyle(Theme.textSecondary).monospacedDigit()
                }
                .padding(.horizontal, 16).frame(minHeight: 44)
                Slider(value: settings.matchThreshold, in: 0.5...0.99, step: 0.01)
                    .tint(Theme.accent).padding(.horizontal, 16).padding(.bottom, 12)
                    .accessibilityLabel("Match strictness")
            }
            .background(Theme.surface.opacity(0.7), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.line))

            Button("Scan all libraries now", systemImage: "arrow.triangle.2.circlepath") { Task { await stores.pcloud.rescan(full: false) } }
                .buttonStyle(.pulsePrimary)
                .disabled(stores.pcloud.status?.connected != true || stores.pcloud.scan.state == .running)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PlatformCard<Extra: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color
    let connected: Bool
    let detail: String
    let route: Route
    @ViewBuilder var extra: Extra

    var body: some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: systemImage)
                        .font(.title2).foregroundStyle(tint)
                        .frame(width: 52, height: 52)
                        .background(tint.opacity(0.16), in: .rect(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
                        Text(detail).font(.footnote).foregroundStyle(Theme.textSecondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Chip(connected ? "Connected" : "Add", systemImage: connected ? "checkmark.circle.fill" : "plus",
                         tint: connected ? Theme.success : Theme.accentSoft)
                }
                extra
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityHint(connected ? "Manage this platform" : "Connect this platform")
    }
}
#endif
