import Foundation
import Observation

@MainActor
@Observable
public final class SceneStore {
    public private(set) var state: LoadState<SceneDetail> = .idle
    public private(set) var busy = false
    public var message: String?
    @ObservationIgnored public let sceneID: Int
    @ObservationIgnored private let api: any PulseAPI

    public init(sceneID: Int, api: any PulseAPI) { self.sceneID = sceneID; self.api = api }

    public func load() async {
        if case .loaded = state {} else { state = .loading }
        do { state = .loaded(try await api.scene(id: sceneID)) }
        catch { state = .failed(error.asPulseError) }
    }

    public func edit(_ edit: SceneEdit) async -> Bool {
        busy = true; defer { busy = false }
        do { state = .loaded(try await api.editScene(id: sceneID, edit)); return true }
        catch { message = error.asPulseError.errorDescription; return false }
    }

    public func unmatch() async {
        busy = true; defer { busy = false }
        do { state = .loaded(try await api.unmatch(sceneID: sceneID)) }
        catch { message = error.asPulseError.errorDescription }
    }

    public func clearProgress() async {
        try? await api.clearProgress(sceneID: sceneID)
        await load()
    }
}

@MainActor
@Observable
public final class PerformerStore {
    public private(set) var state: LoadState<PerformerDetail> = .idle
    public private(set) var refreshing = false
    public var message: String?
    @ObservationIgnored public let performerID: Int
    @ObservationIgnored private let api: any PulseAPI

    public init(performerID: Int, api: any PulseAPI) { self.performerID = performerID; self.api = api }

    public func load() async {
        if case .loaded = state {} else { state = .loading }
        do { state = .loaded(try await api.performer(id: performerID)) }
        catch { state = .failed(error.asPulseError) }
    }

    public func refresh(from source: MetadataProvider?) async {
        refreshing = true; defer { refreshing = false }
        do { state = .loaded(try await api.refreshPerformer(id: performerID, source: source)) }
        catch { message = error.asPulseError.errorDescription }
    }
}

@MainActor
@Observable
public final class StudioStore {
    public private(set) var state: LoadState<StudioDetail> = .idle
    @ObservationIgnored public let studioID: Int
    @ObservationIgnored private let api: any PulseAPI

    public init(studioID: Int, api: any PulseAPI) { self.studioID = studioID; self.api = api }

    public func load() async {
        if case .loaded = state {} else { state = .loading }
        do { state = .loaded(try await api.studio(id: studioID)) }
        catch { state = .failed(error.asPulseError) }
    }
}

@MainActor
@Observable
public final class PeopleStore {
    public var query = PerformerQuery() { didSet { if query != oldValue { schedule() } } }
    public private(set) var performers: [Performer] = []
    public private(set) var studios: [Studio] = []
    public private(set) var isLoading = false
    public private(set) var error: PulseError?
    @ObservationIgnored private var totalPages = 1
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private let api: any PulseAPI

    public init(api: any PulseAPI) { self.api = api }

    private func schedule() {
        task?.cancel()
        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, let self else { return }
            await self.loadPerformers()
        }
    }

    public func loadPerformers() async {
        isLoading = true; error = nil
        var q = query; q.page = 1
        do {
            let page = try await api.performers(q)
            performers = page.items; totalPages = page.totalPages
        } catch { let e = error.asPulseError; if e != .cancelled { self.error = e } }
        isLoading = false
    }

    public func loadMore(current: Performer) async {
        guard query.page < totalPages, performers.last?.id == current.id else { return }
        var q = query; q.page += 1
        if let page = try? await api.performers(q) {
            let known = Set(performers.map(\.id))
            performers.append(contentsOf: page.items.filter { !known.contains($0.id) })
            query.page = q.page; totalPages = page.totalPages
        }
    }

    public func loadStudios(text: String = "") async {
        do { studios = try await api.studios(query: text, favorites: false, page: 1).items }
        catch { self.error = error.asPulseError }
    }
}

@MainActor
@Observable
public final class FavoritesStore {
    public private(set) var state: LoadState<FavoritesBundle> = .idle
    public private(set) var watchlist: [Video] = []
    @ObservationIgnored private let api: any PulseAPI

    public init(api: any PulseAPI) { self.api = api }

    public func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            state = .loaded(try await api.favorites())
            watchlist = (try? await api.watchlist()) ?? []
        } catch { state = .failed(error.asPulseError) }
    }
}
