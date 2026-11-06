#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct SettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(AppSession.self) private var session
    @State private var confirmLock = false

    public init() {}

    public var body: some View {
        List {
            Section {
                connectionCard
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            Section("Library") {
                row(.pcloud, "pCloud", "icloud.fill")
                row(.torbox, "TorBox", "arrow.down.circle.fill")
                row(.matching, "Matching & review", "wand.and.stars")
                row(.sources, "Metadata sources", "checkmark.seal.fill")
            }
            Section("Experience") {
                row(.playback, "Playback", "play.circle.fill")
                row(.privacy, "Privacy & security", "lock.shield.fill")
            }
            Section("Storage") {
                row(.data, "Data & storage", "externaldrive.fill")
                row(.about, "About Pulse", "info.circle.fill")
            }
            Section {
                Button("Lock now", systemImage: "lock.fill") { Task { await session.lock() } }
                Button(session.isDemo ? "Exit demo" : "Disconnect from server", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    confirmLock = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Disconnect from this server?", isPresented: $confirmLock, titleVisibility: .visible) {
            Button("Disconnect", role: .destructive) { session.forgetServer() }
        } message: { Text("You can reconnect any time with the server address.") }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
        .task { await stores.settings.load() }
    }

    private func row(_ page: SettingsPage, _ title: LocalizedStringKey, _ symbol: String) -> some View {
        NavigationLink(value: Route.settings(page)) {
            Label {
                Text(title).foregroundStyle(Theme.text)
            } icon: {
                Image(systemName: symbol).foregroundStyle(Theme.accentSoft)
            }
            .frame(minHeight: 44)
        }
    }

    private var connectionCard: some View {
        HStack(spacing: 14) {
            PulseMark(size: 30, showsWordmark: false)
                .frame(width: 56, height: 56)
                .pulseGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(session.isDemo ? "Demo library" : (session.serverURL?.host ?? "Server")).font(PulseFont.title(.headline)).foregroundStyle(Theme.text)
                Text(session.isDemo ? "Sample data, no server needed" : "Connected").font(.footnote).foregroundStyle(Theme.success)
            }
            Spacer()
            Circle().fill(Theme.success).frame(width: 10, height: 10)
                .shadow(color: Theme.success, radius: 5)
                .accessibilityHidden(true)
        }
        .padding(16)
        .pulseGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.vertical, 6)
    }
}

struct SettingsPageView: View {
    let page: SettingsPage

    var body: some View {
        switch page {
        case .playback: PlaybackSettingsView()
        case .privacy: PrivacySettingsView()
        case .pcloud: PcloudSettingsView()
        case .torbox: TorboxView()
        case .matching: MatchingView()
        case .sources: SourcesSettingsView()
        case .data: DataSettingsView()
        case .about: AboutView()
        }
    }
}

/// Shared page chrome for settings forms.
struct SettingsForm<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        Form { content }
            .scrollContentBackground(.hidden)
            .pulseScreenBackground(intensity: 0.4)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
