#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct TorboxView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var apiKey = ""
    @State private var magnet = ""
    @State private var toast: String?

    var body: some View {
        let store = stores.torbox
        SettingsForm(title: "TorBox") {
            if store.status?.linked == true { linked(store) } else { link(store) }
        }
        .task { await store.load(); store.startPolling() }
        .onDisappear { store.stopPolling() }
        .pulseToast($toast)
        .onChange(of: store.message) { _, m in if let m { toast = m; store.message = nil } }
    }

    @ViewBuilder
    private func linked(_ store: TorboxStore) -> some View {
        Section("Account") {
            LabeledContent("Plan", value: store.status?.planName ?? "—")
            if let email = store.status?.email { LabeledContent("Account", value: email) }
        }
        Section("Add download") {
            TextField("Magnet link or URL", text: $magnet, axis: .vertical).textInputAutocapitalization(.never).autocorrectionDisabled().lineLimit(1...3)
            Button("Add to TorBox", systemImage: "plus.circle.fill") {
                Task { if await store.add(magnet) { magnet = "" } }
            }
            .disabled(magnet.trimmingCharacters(in: .whitespaces).isEmpty || store.busy)
        }
        Section {
            Picker("Show", selection: Binding(get: { store.filter }, set: { store.filter = $0; Task { await store.refreshItems() } })) {
                Text("All").tag(TorboxKind?.none)
                ForEach(TorboxKind.allCases, id: \.self) { Text($0.label).tag(TorboxKind?.some($0)) }
            }
            .pickerStyle(.segmented)
            if store.items.isEmpty {
                Text("No downloads yet.").foregroundStyle(Theme.textSecondary)
            }
            ForEach(store.items) { item in TorboxRow(item: item, store: store) }
        } header: { Text("Downloads") }
        Section { Button("Unlink TorBox", role: .destructive) { Task { await store.unlink() } } }
    }

    @ViewBuilder
    private func link(_ store: TorboxStore) -> some View {
        Section {
            Text("Link your TorBox account to stream cached torrents and add them to your Pulse library.").font(PulseFont.ui(.subheadline)).foregroundStyle(Theme.textSecondary)
            SecureField("TorBox API key", text: $apiKey).textInputAutocapitalization(.never).autocorrectionDisabled()
            Button("Link account") { Task { await store.link(apiKey: apiKey.isEmpty ? nil : apiKey); apiKey = "" } }
                .disabled(store.busy)
        } footer: { Text("Leave the key empty to use the key saved on your server.") }
    }
}

private struct TorboxRow: View {
    let item: TorboxItem
    let store: TorboxStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name).font(PulseFont.ui(.subheadline, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
            ProgressView(value: min(max(item.progress, 0), 1)).tint(item.ready ? Theme.success : Theme.accent)
            HStack(spacing: 8) {
                Text(Format.bytes(item.size))
                Text(item.ready ? "Ready" : Format.percent(item.progress))
                if item.downloadSpeed > 0 { Text(Format.speed(item.downloadSpeed)) }
                if let eta = Format.eta(item.eta), !item.ready { Text(eta) }
                Spacer()
                if let seeds = item.seeds { Label("\(seeds)", systemImage: "arrow.up.circle").labelStyle(.titleAndIcon) }
            }
            .font(PulseFont.timecode(.caption)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            if item.ready { Button("Add to library", systemImage: "square.and.arrow.down") { Task { await store.importToLibrary(item) } } }
            Button("Pause", systemImage: "pause") { Task { await store.control(item, "pause") } }
            Button("Resume", systemImage: "play") { Task { await store.control(item, "resume") } }
            Button("Delete", systemImage: "trash", role: .destructive) { Task { await store.control(item, "delete") } }
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) { Task { await store.control(item, "delete") } }
        }
        .swipeActions(edge: .leading) {
            if item.ready { Button("Add", systemImage: "square.and.arrow.down") { Task { await store.importToLibrary(item) } }.tint(Theme.accent) }
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
