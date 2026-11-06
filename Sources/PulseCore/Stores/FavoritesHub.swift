import Foundation
import Observation

/// Optimistic favourite/watchlist state shared by every screen.
@MainActor
@Observable
public final class FavoritesHub {
    private var overrides: [String: Bool] = [:]
    public private(set) var lastError: String?
    @ObservationIgnored private let api: any PulseAPI

    public init(api: any PulseAPI) { self.api = api }

    private func key(_ type: FavoriteType, _ id: Int, _ list: FavoriteList) -> String { "\(type.rawValue).\(list.rawValue).\(id)" }

    public func isFavorite(_ scene: Video) -> Bool { overrides[key(.scene, scene.id, .favorites)] ?? scene.favorite }
    public func isWatchlisted(_ scene: Video) -> Bool { overrides[key(.scene, scene.id, .watchlist)] ?? scene.watchlist }
    public func isFavorite(_ performer: Performer) -> Bool { overrides[key(.performer, performer.id, .favorites)] ?? performer.favorite }
    public func isFavorite(_ studio: Studio) -> Bool { overrides[key(.studio, studio.id, .favorites)] ?? studio.favorite }

    public func toggle(_ scene: Video, list: FavoriteList = .favorites) async {
        let current = list == .favorites ? isFavorite(scene) : isWatchlisted(scene)
        await set(.scene, id: scene.id, list: list, to: !current)
    }

    public func toggle(_ performer: Performer) async { await set(.performer, id: performer.id, list: .favorites, to: !isFavorite(performer)) }
    public func toggle(_ studio: Studio) async { await set(.studio, id: studio.id, list: .favorites, to: !isFavorite(studio)) }

    private func set(_ type: FavoriteType, id: Int, list: FavoriteList, to value: Bool) async {
        let k = key(type, id, list)
        let previous = overrides[k]
        overrides[k] = value
        do { try await api.setFavorite(type, id: id, value: value, list: list); lastError = nil }
        catch {
            overrides[k] = previous
            lastError = error.asPulseError.errorDescription
        }
    }
}
