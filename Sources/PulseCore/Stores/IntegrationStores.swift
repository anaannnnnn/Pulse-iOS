import Foundation
import Observation

@MainActor
@Observable
public final class PcloudStore {
    public private(set) var status: PcloudStatus?
    public private(set) var scan: ScanStatus = .idle
    public private(set) var folders: [ScanFolder] = []
    public var message: String?
    public private(set) var busy = false
    @ObservationIgnored private let api: any PulseAPI
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    public init(api: any PulseAPI) { self.api = api }

    public func load() async {
        status = try? await api.pcloudStatus()
        scan = (try? await api.scanStatus()) ?? .idle
        folders = (try? await api.scanFolders()) ?? []
        if scan.state == .running { startPolling() }
    }

    public func authorizeURL(manual: Bool) async -> URL? {
        do { return URL(string: try await api.pcloudAuthorizeURL(manual: manual).url) }
        catch { message = error.asPulseError.errorDescription; return nil }
    }

    public func exchange(_ text: String) async -> Bool {
        busy = true; defer { busy = false }
        do { status = try await api.pcloudExchange(codeOrURL: text.trimmingCharacters(in: .whitespacesAndNewlines)); return status?.connected == true }
        catch { message = error.asPulseError.errorDescription; return false }
    }

    public func disconnect(purge: Bool) async {
        busy = true; defer { busy = false }
        try? await api.pcloudDisconnect(purge: purge)
        await load()
    }

    public func rescan(full: Bool) async {
        do { scan = try await api.rescan(full: full); startPolling() }
        catch { message = error.asPulseError.errorDescription }
    }

    public func save(folders newFolders: [ScanFolder]) async {
        do { folders = try await api.setScanFolders(newFolders) }
        catch { message = error.asPulseError.errorDescription }
    }

    public func listing(_ id: Int) async -> PcloudFolderListing? {
        do { return try await api.pcloudFolders(folderID: id) }
        catch { message = error.asPulseError.errorDescription; return nil }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                if let s = try? await self.api.scanStatus() { self.scan = s; if s.state != .running { return } }
            }
        }
    }

    public func stopPolling() { pollTask?.cancel() }
}

@MainActor
@Observable
public final class TorboxStore {
    public private(set) var status: TorboxStatus?
    public private(set) var items: [TorboxItem] = []
    public var filter: TorboxKind?
    public var message: String?
    public private(set) var busy = false
    @ObservationIgnored private let api: any PulseAPI
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    public init(api: any PulseAPI) { self.api = api }

    public func load() async {
        status = try? await api.torboxStatus()
        guard status?.linked == true else { items = []; return }
        await refreshItems()
    }

    public func refreshItems() async {
        do { items = try await api.torboxDownloads(kind: filter) }
        catch { message = error.asPulseError.errorDescription }
    }

    public func link(apiKey: String?) async {
        busy = true; defer { busy = false }
        do { status = try await api.torboxLink(apiKey: apiKey); await refreshItems() }
        catch { message = error.asPulseError.errorDescription }
    }

    public func unlink() async { try? await api.torboxUnlink(); await load() }

    public func add(_ text: String) async -> Bool {
        busy = true; defer { busy = false }
        do { let r = try await api.torboxAdd(magnetOrURL: text.trimmingCharacters(in: .whitespacesAndNewlines)); message = r.message; await refreshItems(); return true }
        catch { message = error.asPulseError.errorDescription; return false }
    }

    public func control(_ item: TorboxItem, _ operation: String) async {
        try? await api.torboxControl(kind: item.type, id: item.id, operation: operation)
        await refreshItems()
    }

    public func importToLibrary(_ item: TorboxItem) async {
        do { let r = try await api.torboxImport(kind: item.type, ids: [item.id]); message = "Added \(r.added) of \(r.seen) files to your library." }
        catch { message = error.asPulseError.errorDescription }
    }

    public func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                await self?.refreshItems()
            }
        }
    }

    public func stopPolling() { pollTask?.cancel() }
}

@MainActor
@Observable
public final class MatchStore {
    public private(set) var job: MatchJobStatus = .idle
    public private(set) var unmatched: [Video] = []
    public private(set) var sources: [MetadataSource] = []
    public private(set) var tests: [MetadataProvider: ProviderTest] = [:]
    public var message: String?
    @ObservationIgnored private let api: any PulseAPI
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    public init(api: any PulseAPI) { self.api = api }

    public func load() async {
        async let status = try? api.matchStatus()
        async let list = try? api.unmatched(page: 1)
        async let src = try? api.metadataSources()
        job = await status ?? .idle
        unmatched = await list?.items ?? []
        sources = await src ?? []
        if job.state == .running { startPolling() }
    }

    public func run(_ action: MatchAction) async {
        do { job = try await api.matchControl(action); if job.state == .running { startPolling() } }
        catch { message = error.asPulseError.errorDescription }
    }

    public func test(_ provider: MetadataProvider) async {
        do { tests[provider] = try await api.testProvider(provider) }
        catch { tests[provider] = ProviderTest(ok: false, status: "error", hint: error.asPulseError.errorDescription) }
    }

    public func ignore(_ scene: Video) async {
        try? await api.ignore(sceneID: scene.id)
        unmatched.removeAll { $0.id == scene.id }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                if let s = try? await self.api.matchStatus() {
                    self.job = s
                    if s.state != .running { await self.load(); return }
                }
            }
        }
    }

    public func stopPolling() { pollTask?.cancel() }
}

@MainActor
@Observable
public final class MatchSearchStore {
    public private(set) var candidates: [MatchCandidate] = []
    public private(set) var isSearching = false
    public private(set) var applying = false
    public var message: String?
    @ObservationIgnored public let scene: Video
    @ObservationIgnored private let api: any PulseAPI

    public init(scene: Video, api: any PulseAPI) { self.scene = scene; self.api = api }

    public func search(_ text: String?) async {
        isSearching = true; defer { isSearching = false }
        do { candidates = try await api.searchMatches(sceneID: scene.id, query: text).candidates }
        catch { message = error.asPulseError.errorDescription }
    }

    public func apply(_ candidate: MatchCandidate) async -> SceneDetail? {
        applying = true; defer { applying = false }
        do { return try await api.applyMatch(sceneID: scene.id, candidate: candidate) }
        catch { message = error.asPulseError.errorDescription; return nil }
    }
}

@MainActor
@Observable
public final class SettingsStore {
    public var settings = ServerSettings()
    public private(set) var loaded = false
    public private(set) var isSaving = false
    public var message: String?
    @ObservationIgnored private let api: any PulseAPI
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    public init(api: any PulseAPI) { self.api = api }

    public func load() async {
        do { settings = try await api.settings(); loaded = true }
        catch { message = error.asPulseError.errorDescription }
    }

    /// Call after any edit; coalesces rapid toggles into one PUT.
    public func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self else { return }
            await self.save()
        }
    }

    public func save() async {
        isSaving = true; defer { isSaving = false }
        do { settings = try await api.updateSettings(settings) }
        catch { message = error.asPulseError.errorDescription }
    }

    public func changePin(current: String, new: String) async -> Bool {
        do { try await api.changePin(current: current, new: new); return true }
        catch { message = error.asPulseError.errorDescription; return false }
    }

    public func clear(_ scope: ClearDataScope) async {
        do { try await api.clearData(scope); message = "\(scope.label) cleared." }
        catch { message = error.asPulseError.errorDescription }
    }
}
