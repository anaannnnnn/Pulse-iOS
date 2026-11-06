import Foundation
import Observation

@MainActor
@Observable
public final class HomeStore {
    public private(set) var state: LoadState<HomeFeed> = .idle
    @ObservationIgnored private let api: any PulseAPI

    public init(api: any PulseAPI) { self.api = api }

    public func load(force: Bool = false) async {
        if case .loaded = state, !force { return }
        if case .loaded = state {} else { state = .loading }
        do { state = .loaded(try await api.home()) }
        catch { state = .failed(error.asPulseError) }
    }

    public var libraryIsEmpty: Bool {
        guard case .loaded(let feed) = state else { return false }
        return feed.hero.isEmpty && feed.rails.allSatisfy(\.items.isEmpty)
    }
}
