#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct PcloudSettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(\.openURL) private var openURL
    @State private var code = ""
    @State private var picking = false
    @State private var confirmDisconnect = false
    @State private var toast: String?

    var body: some View {
        let store = stores.pcloud
        SettingsForm(title: "pCloud") {
            if store.status?.connected == true { connected(store) } else { connect(store) }
        }
        .task { await store.load() }
        .onDisappear { store.stopPolling() }
        .sheet(isPresented: $picking) { PcloudFolderPicker().presentationDetents([.large]) }
        .confirmationDialog("Disconnect pCloud?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
            Button("Disconnect, keep my library", role: .destructive) { Task { await store.disconnect(purge: false) } }
            Button("Disconnect and remove videos", role: .destructive) { Task { await store.disconnect(purge: true) } }
        }
        .pulseToast($toast)
        .onChange(of: store.message) { _, m in if let m { toast = m; store.message = nil } }
    }

    @ViewBuilder
    private func connected(_ store: PcloudStore) -> some View {
        Section("Account") {
            LabeledContent("Signed in as", value: store.status?.email ?? "—")
            if let quota = store.status?.quota, quota > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: store.status?.usedFraction ?? 0).tint(Theme.accent)
                    Text("\(Format.bytes(Int64(store.status?.usedQuota ?? 0))) of \(Format.bytes(Int64(quota))) used")
                        .font(.footnote).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        Section {
            Button("Choose folders to scan", systemImage: "folder.badge.gearshape") { picking = true }
            if store.folders.isEmpty {
                Text("Scanning your whole account").font(.footnote).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(store.folders) { Label($0.path ?? $0.name ?? "Folder", systemImage: "folder.fill").font(.footnote) }
            }
        } header: { Text("Folders") }
        Section("Scan") {
            scanStatus(store.scan)
            Button("Scan for new videos", systemImage: "arrow.triangle.2.circlepath") { Task { await store.rescan(full: false) } }
                .disabled(store.scan.state == .running)
            Button("Full rescan", systemImage: "arrow.clockwise.circle") { Task { await store.rescan(full: true) } }
                .disabled(store.scan.state == .running)
        }
        Section { Button("Disconnect", role: .destructive) { confirmDisconnect = true } }
    }

    @ViewBuilder
    private func scanStatus(_ scan: ScanStatus) -> some View {
        switch scan.state {
        case .running:
            VStack(alignment: .leading, spacing: 6) {
                HStack { ProgressView(); Text("Scanning…").font(.subheadline.weight(.semibold)) }
                if let path = scan.currentPath { Text(path).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1) }
                Text("\(scan.filesSeen) files · \(scan.videosFound) videos · \(scan.added) new").font(.caption.monospacedDigit()).foregroundStyle(Theme.textSecondary)
            }
        case .error:
            Label(scan.error ?? "The last scan failed.", systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.danger).font(.footnote)
        case .idle:
            if scan.videosFound > 0 {
                Text("Last scan: \(scan.videosFound) videos, \(scan.added) added, \(scan.removed) removed.").font(.footnote).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func connect(_ store: PcloudStore) -> some View {
        Section {
            Text("Pulse streams the videos in your pCloud. Sign in once on pCloud's own page, copy the code it shows, and paste it below.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
            Button("Open pCloud sign-in", systemImage: "safari") {
                Task { if let url = await store.authorizeURL(manual: true) { openURL(url) } }
            }
        } header: { Text("Step 1") }
        Section {
            TextField("Paste code or full address", text: $code, axis: .vertical)
                .textInputAutocapitalization(.never).autocorrectionDisabled().lineLimit(1...4)
            Button {
                Task { if await store.exchange(code) { code = ""; toast = "pCloud connected." } }
            } label: {
                HStack { if store.busy { ProgressView() }; Text("Connect") }
            }
            .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || store.busy)
        } header: { Text("Step 2") }
    }
}

struct PcloudFolderPicker: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(\.dismiss) private var dismiss
    @State private var stack: [PcloudFolderListing] = []
    @State private var selected: [ScanFolder] = []
    @State private var loading = false

    var body: some View {
        NavigationStack {
            List {
                if let listing = stack.last {
                    if listing.parentId != nil {
                        Button("Up one level", systemImage: "arrow.up.left") { stack.removeLast() }
                    }
                    Section("\(listing.path) · \(listing.videoCount) videos") {
                        ForEach(listing.folders) { folder in
                            HStack {
                                Button { Task { await open(folder.folderId) } } label: {
                                    Label(folder.name, systemImage: "folder.fill").foregroundStyle(Theme.text)
                                }
                                Spacer()
                                Button { toggle(folder) } label: {
                                    Image(systemName: isSelected(folder) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected(folder) ? Theme.accentSoft : Theme.textTertiary)
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel(isSelected(folder) ? "Deselect \(folder.name)" : "Select \(folder.name)")
                            }
                        }
                    }
                } else if loading { ProgressView().frame(maxWidth: .infinity) }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Scan folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await stores.pcloud.save(folders: selected); dismiss() } }
                }
            }
            .task {
                selected = stores.pcloud.folders
                await open(0)
            }
        }
    }

    private func isSelected(_ folder: PcloudFolder) -> Bool { selected.contains { $0.folderId == folder.folderId } }

    private func toggle(_ folder: PcloudFolder) {
        if let i = selected.firstIndex(where: { $0.folderId == folder.folderId }) { selected.remove(at: i) }
        else { selected.append(ScanFolder(folderId: folder.folderId, path: folder.path, name: folder.name)) }
    }

    private func open(_ id: Int) async {
        loading = true
        if let listing = await stores.pcloud.listing(id) { stack.append(listing) }
        loading = false
    }
}
#endif
