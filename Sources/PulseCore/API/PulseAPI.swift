import Foundation

/// Everything the app needs from a Pulse server. `PulseClient` talks HTTP; `DemoClient` serves sample data.
public protocol PulseAPI: Sendable {
    var baseURL: URL { get }

    // Session
    func health() async throws -> HealthInfo
    func session() async throws -> SessionState
    func unlock(pin: String) async throws
    func lock() async throws
    func changePin(current: String, new: String) async throws

    // Browse
    func home() async throws -> HomeFeed
    func library(_ query: LibraryQuery) async throws -> Paged<Video>
    func facets() async throws -> LibraryFacets
    func scene(id: Int) async throws -> SceneDetail
    func editScene(id: Int, _ edit: SceneEdit) async throws -> SceneDetail
    func performers(_ query: PerformerQuery) async throws -> Paged<Performer>
    func performer(id: Int) async throws -> PerformerDetail
    func refreshPerformer(id: Int, source: MetadataProvider?) async throws -> PerformerDetail
    func studios(query: String?, favorites: Bool, page: Int) async throws -> Paged<Studio>
    func studio(id: Int) async throws -> StudioDetail
    func tags(query: String?, page: Int) async throws -> Paged<Tag>
    func continueWatching(limit: Int) async throws -> [Video]
    func recentlyAdded(limit: Int) async throws -> [Video]

    // Favourites & watchlist
    func favorites() async throws -> FavoritesBundle
    func watchlist() async throws -> [Video]
    func setFavorite(_ type: FavoriteType, id: Int, value: Bool, list: FavoriteList) async throws

    // Playback
    func stream(sceneID: Int) async throws -> StreamInfo
    func saveProgress(sceneID: Int, position: Double, duration: Double?, completed: Bool?) async throws
    func clearProgress(sceneID: Int) async throws
    func subtitleCues(for track: SubtitleTrack) async throws -> [SubtitleCue]
    func absoluteURL(_ path: String) -> URL?

    // pCloud
    func pcloudStatus() async throws -> PcloudStatus
    func pcloudAuthorizeURL(manual: Bool) async throws -> PcloudAuthorizeURL
    func pcloudExchange(codeOrURL: String) async throws -> PcloudStatus
    func pcloudDisconnect(purge: Bool) async throws
    func pcloudFolders(folderID: Int) async throws -> PcloudFolderListing
    func scanFolders() async throws -> [ScanFolder]
    func setScanFolders(_ folders: [ScanFolder]) async throws -> [ScanFolder]
    func rescan(full: Bool) async throws -> ScanStatus
    func scanStatus() async throws -> ScanStatus

    // Matching
    func matchStatus() async throws -> MatchJobStatus
    func matchControl(_ action: MatchAction) async throws -> MatchJobStatus
    func unmatched(page: Int) async throws -> Paged<Video>
    func searchMatches(sceneID: Int, query: String?) async throws -> MatchResponse
    func applyMatch(sceneID: Int, candidate: MatchCandidate) async throws -> SceneDetail
    func unmatch(sceneID: Int) async throws -> SceneDetail
    func ignore(sceneID: Int) async throws
    func metadataSources() async throws -> [MetadataSource]
    func testProvider(_ provider: MetadataProvider) async throws -> ProviderTest

    // TorBox
    func torboxStatus() async throws -> TorboxStatus
    func torboxLink(apiKey: String?) async throws -> TorboxStatus
    func torboxUnlink() async throws
    func torboxDownloads(kind: TorboxKind?) async throws -> [TorboxItem]
    func torboxAdd(magnetOrURL: String) async throws -> TorboxAddResult
    func torboxControl(kind: TorboxKind, id: Int, operation: String) async throws
    func torboxStream(kind: TorboxKind, id: Int, fileID: Int) async throws -> TorboxStream
    func torboxImport(kind: TorboxKind, ids: [Int]) async throws -> TorboxImportResult

    // Settings
    func settings() async throws -> ServerSettings
    func updateSettings(_ settings: ServerSettings) async throws -> ServerSettings
    func clearData(_ scope: ClearDataScope) async throws
}

public enum FavoriteType: String, Sendable { case scene, performer, studio }
public enum FavoriteList: String, Sendable { case favorites, watchlist }

public struct LibraryQuery: Hashable, Sendable {
    public var text: String = ""
    public var sort: LibrarySort = .added
    public var ascending = false
    public var tagIDs: [Int] = []
    public var performerIDs: [Int] = []
    public var studioIDs: [Int] = []
    public var yearFrom: Int?
    public var yearTo: Int?
    public var matched: Bool?
    public var favoritesOnly = false
    public var watchlistOnly = false
    public var watched: WatchedFilter = .any
    public var source: SceneSource?
    public var status: MatchStatus?
    public var minDuration: Double?
    public var maxDuration: Double?
    public var page = 1
    public var pageSize = 40

    public init() {}

    public var activeFilterCount: Int {
        var n = 0
        if !tagIDs.isEmpty { n += 1 }
        if !performerIDs.isEmpty { n += 1 }
        if !studioIDs.isEmpty { n += 1 }
        if yearFrom != nil || yearTo != nil { n += 1 }
        if matched != nil { n += 1 }
        if favoritesOnly { n += 1 }
        if watchlistOnly { n += 1 }
        if watched != .any { n += 1 }
        if source != nil { n += 1 }
        if status != nil { n += 1 }
        if minDuration != nil || maxDuration != nil { n += 1 }
        return n
    }

    public mutating func clearFilters() {
        let keepText = text, keepSort = sort, keepAsc = ascending, keepSize = pageSize
        self = LibraryQuery()
        text = keepText; sort = keepSort; ascending = keepAsc; pageSize = keepSize
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) { if let value, !value.isEmpty { items.append(.init(name: name, value: value)) } }
        add("q", text.trimmingCharacters(in: .whitespaces))
        add("sort", sort.rawValue)
        add("order", ascending ? "asc" : "desc")
        add("tags", tagIDs.map(String.init).joined(separator: ","))
        add("performers", performerIDs.map(String.init).joined(separator: ","))
        add("studio", studioIDs.map(String.init).joined(separator: ","))
        if let yearFrom, let yearTo { add("year", yearFrom == yearTo ? "\(yearFrom)" : "\(yearFrom)-\(yearTo)") }
        else if let yearFrom { add("year", "\(yearFrom)") }
        else if let yearTo { add("year", "\(yearTo)") }
        if let matched { add("matched", matched ? "true" : "false") }
        if favoritesOnly { add("favorites", "true") }
        if watchlistOnly { add("watchlist", "true") }
        if watched != .any { add("watched", watched.rawValue) }
        add("source", source?.rawValue)
        add("status", status?.rawValue)
        if let minDuration { add("minDuration", String(Int(minDuration))) }
        if let maxDuration { add("maxDuration", String(Int(maxDuration))) }
        add("page", "\(page)")
        add("pageSize", "\(pageSize)")
        return items
    }
}

public struct PerformerQuery: Hashable, Sendable {
    public enum Sort: String, CaseIterable, Sendable, Identifiable {
        case name, scenes, added
        public var id: String { rawValue }
        public var label: String { self == .name ? "Name" : (self == .scenes ? "Most scenes" : "Recently added") }
    }
    public var text: String = ""
    public var sort: Sort = .scenes
    public var ascending = false
    public var favoritesOnly = false
    public var gender: String?
    public var page = 1
    public var pageSize = 60

    public init() {}

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) { if let value, !value.isEmpty { items.append(.init(name: name, value: value)) } }
        add("q", text.trimmingCharacters(in: .whitespaces))
        add("sort", sort.rawValue)
        add("order", ascending ? "asc" : "desc")
        if favoritesOnly { add("favorites", "true") }
        add("gender", gender)
        add("page", "\(page)")
        add("pageSize", "\(pageSize)")
        return items
    }
}
