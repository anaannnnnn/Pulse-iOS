#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import Observation
import PulseCore

/// Every store for one connected server. Rebuilt when the server or demo mode changes.
@MainActor
@Observable
public final class StoreBundle {
    public let api: any PulseAPI
    public let home: HomeStore
    public let library: LibraryStore
    public let favorites: FavoritesStore
    public let hub: FavoritesHub
    public let people: PeopleStore
    public let settings: SettingsStore
    public let pcloud: PcloudStore
    public let torbox: TorboxStore
    public let matching: MatchStore

    public init(api: any PulseAPI) {
        self.api = api
        home = HomeStore(api: api)
        library = LibraryStore(api: api)
        favorites = FavoritesStore(api: api)
        hub = FavoritesHub(api: api)
        people = PeopleStore(api: api)
        settings = SettingsStore(api: api)
        pcloud = PcloudStore(api: api)
        torbox = TorboxStore(api: api)
        matching = MatchStore(api: api)
    }
}
#endif
