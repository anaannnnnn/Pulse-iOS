import Foundation
import Observation

@MainActor
@Observable
public final class LibraryStore {
    public var query = LibraryQuery() {
        didSet { if query != oldValue { scheduleReload() } }
    }
    public private(set) var scenes: [Video] = []
    public private(set) var total = 0
    public private(set) var isLoading = false
    public private(set) var isLoadingMore = false
    public private(set) var error: PulseError?
    public private(set) var facets: LibraryFacets?
    @ObservationIgnored private var totalPages = 1
    @ObservationIgnored private var reloadTask: Task<Void, Never>?
    @ObservationIgnored private let api: any PulseAPI

    public init(api: any PulseAPI, initial: LibraryQuery = LibraryQuery()) {
        self.api = api
        self.query = initial
    }

    public var canLoadMore: Bool { query.page < totalPages && !isLoadingMore && !isLoading }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            // Debounce typing in the search field.
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, let self else { return }
            await self.reload()
        }
    }

    public func reload() async {
        var q = query
        q.page = 1
        isLoading = true
        error = nil
        do {
            let page = try await api.library(q)
            guard !Task.isCancelled else { return }
            scenes = page.items
            total = page.total
            totalPages = page.totalPages
            query.page = 1
        } catch {
            let e = error.asPulseError
            if e != .cancelled { self.error = e }
        }
        isLoading = false
    }

    public func loadMoreIfNeeded(current scene: Video) async {
        guard canLoadMore, let index = scenes.firstIndex(where: { $0.id == scene.id }), index >= scenes.count - 8 else { return }
        isLoadingMore = true
        var q = query
        q.page += 1
        do {
            let page = try await api.library(q)
            let known = Set(scenes.map(\.id))
            scenes.append(contentsOf: page.items.filter { !known.contains($0.id) })
            totalPages = page.totalPages
            query.page = q.page
        } catch { self.error = error.asPulseError }
        isLoadingMore = false
    }

    public func loadFacets() async {
        if facets != nil { return }
        facets = try? await api.facets()
    }
}
