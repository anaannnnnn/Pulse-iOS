import Foundation

/// In-memory `PulseAPI` with sample data: App Store review, previews, tests, and "try without a server".
public actor DemoStore {
    var scenes: [Video]
    var performers: [Performer]
    var studios: [Studio]
    var tags: [Tag]
    var watchlist: Set<Int> = []
    var settings = ServerSettings()
    var pcloud = PcloudStatus(connected: true, email: "demo@pulse.app", quota: 2_000_000_000_000, usedQuota: 640_000_000_000)
    var torboxLinked = true

    init() {
        let studioNames = ["Northlight", "Velvet Room", "Atlas Films", "Halcyon", "Monarch"]
        let performerNames = ["Ava Laurent", "Mira Solis", "Noor Hadid", "Elena Voss", "Kai Moreno", "Zara Quinn", "Leila Park", "Iris Bell"]
        let tagNames = ["Cinematic", "Outdoor", "Studio", "Classic", "4K", "POV", "Story", "Award winner"]
        studios = studioNames.enumerated().map { Studio(id: $0.offset + 1, name: $0.element, sceneCount: 6, favorite: $0.offset == 0) }
        performers = performerNames.enumerated().map { Performer(id: $0.offset + 1, name: $0.element, sceneCount: 5, favorite: $0.offset < 2) }
        tags = tagNames.enumerated().map { Tag(id: $0.offset + 1, name: $0.element, sceneCount: 8) }
        var list: [Video] = []
        let titles = ["Midnight Reel", "Golden Hour", "Paper Moons", "Slow Burn", "Velvet Hours", "The Long Take",
                      "After Dark", "City Lights", "Silk Road", "Blue Room", "Night Shift", "Last Train",
                      "Afterglow", "Red Carpet", "Summer Rain", "Neon Dreams", "Quiet Storm", "Echoes",
                      "Moonlit", "High Tide", "Late Checkout", "Open Roof", "Gilded", "Wild Card"]
        for (i, title) in titles.enumerated() {
            let studio = studioNames.indices.contains(i % 5) ? StudioRef(id: i % 5 + 1, name: studioNames[i % 5]) : nil
            let cast = [performers[i % 8], performers[(i + 3) % 8]].map { PerformerRef(id: $0.id, name: $0.name, image: nil) }
            let duration = Double(1500 + (i * 137) % 2400)
            let progress: WatchProgress? = i % 4 == 0
                ? WatchProgress(position: duration * 0.35, duration: duration, percent: 0.35, completed: false) : nil
            list.append(Video(id: i + 1, title: title, duration: duration, height: i % 5 == 0 ? 2160 : 1080,
                              year: 2019 + i % 7, studio: studio, performers: cast, progress: progress,
                              favorite: i % 6 == 0))
        }
        scenes = list
    }

    func updateScene(_ id: Int, _ change: (inout Video) -> Void) {
        if let i = scenes.firstIndex(where: { $0.id == id }) { change(&scenes[i]) }
    }

    func setFavorite(_ type: FavoriteType, id: Int, value: Bool, list: FavoriteList) {
        switch type {
        case .scene:
            if list == .watchlist { updateScene(id) { $0.watchlist = value } }
            else { updateScene(id) { $0.favorite = value } }
        case .performer:
            if let i = performers.firstIndex(where: { $0.id == id }) { performers[i].favorite = value }
        case .studio:
            if let i = studios.firstIndex(where: { $0.id == id }) { studios[i].favorite = value }
        }
    }

    func setSettings(_ s: ServerSettings) { settings = s }
    func setProgress(_ id: Int, position: Double, duration: Double?, completed: Bool?) {
        updateScene(id) {
            let total = duration ?? $0.duration ?? 1
            $0.progress = WatchProgress(position: position, duration: total, percent: position / max(total, 1),
                                        completed: completed ?? (position / max(total, 1) >= 0.92))
        }
    }
    func clearProgress(_ id: Int) { updateScene(id) { $0.progress = nil } }
    func setTorbox(_ linked: Bool) { torboxLinked = linked }
}

public final class DemoClient: PulseAPI, Sendable {
    public let baseURL = URL(string: "https://demo.pulse.local")!
    private let store = DemoStore()
    private static let sampleStream = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"

    public init() {}

    private func pause() async { try? await Task.sleep(for: .milliseconds(220)) }

    public func absoluteURL(_ path: String) -> URL? { URL(string: path) }
    public func health() async throws -> HealthInfo { HealthInfo(ok: true, version: "demo", time: nil) }
    public func session() async throws -> SessionState { SessionState(locked: false) }
    public func signIn(email: String, password: String) async throws { await pause() }
    public func signOut() async throws {}
    public func changePassword(current: String, new: String) async throws { await pause() }

    public func home() async throws -> HomeFeed {
        await pause()
        let all = await store.scenes
        let performers = await store.performers
        let inProgress = all.filter(\.isInProgress)
        var rails: [HomeRail] = []
        if !inProgress.isEmpty { rails.append(HomeRail(id: "continue", title: "Continue watching", kind: .scenes, items: inProgress.map(RailItem.scene))) }
        rails.append(HomeRail(id: "recent", title: "Recently added", kind: .scenes, items: all.suffix(10).reversed().map(RailItem.scene)))
        rails.append(HomeRail(id: "top-performers", title: "Top performers", kind: .performers, items: performers.map(RailItem.performer)))
        rails.append(HomeRail(id: "favorites", title: "Favourites", kind: .scenes, items: all.filter(\.favorite).map(RailItem.scene)))
        rails.append(HomeRail(id: "unwatched", title: "Unwatched", kind: .scenes, items: all.filter { $0.progress == nil }.prefix(10).map(RailItem.scene)))
        return HomeFeed(hero: Array(all.prefix(5)), rails: rails)
    }

    public func library(_ query: LibraryQuery) async throws -> Paged<Video> {
        await pause()
        var items = await store.scenes
        let text = query.text.lowercased()
        if !text.isEmpty {
            items = items.filter { $0.title.lowercased().contains(text) || $0.performers.contains { $0.name.lowercased().contains(text) } }
        }
        if let min = query.minDuration { items = items.filter { ($0.duration ?? 0) >= min } }
        if let max = query.maxDuration { items = items.filter { ($0.duration ?? 0) <= max } }
        if query.favoritesOnly { items = items.filter(\.favorite) }
        if query.watchlistOnly { items = items.filter(\.watchlist) }
        if !query.studioIDs.isEmpty { items = items.filter { query.studioIDs.contains($0.studio?.id ?? -1) } }
        if !query.performerIDs.isEmpty { items = items.filter { s in query.performerIDs.allSatisfy { id in s.performers.contains { $0.id == id } } } }
        if let from = query.yearFrom { items = items.filter { ($0.year ?? 0) >= from } }
        if let to = query.yearTo { items = items.filter { ($0.year ?? 9999) <= to } }
        switch query.watched {
        case .any: break
        case .true: items = items.filter { $0.progress?.completed == true }
        case .false: items = items.filter { $0.progress == nil }
        case .inprogress: items = items.filter(\.isInProgress)
        }
        switch query.sort {
        case .title: items.sort { $0.title < $1.title }
        case .duration: items.sort { ($0.duration ?? 0) > ($1.duration ?? 0) }
        case .date: items.sort { ($0.year ?? 0) > ($1.year ?? 0) }
        case .random: items.shuffle()
        default: items.sort { $0.id > $1.id }
        }
        if query.ascending { items.reverse() }
        let start = (query.page - 1) * query.pageSize
        let slice = start < items.count ? Array(items[start..<min(start + query.pageSize, items.count)]) : []
        return Paged(items: slice, page: query.page, pageSize: query.pageSize, total: items.count,
                     totalPages: max(1, Int((Double(items.count) / Double(query.pageSize)).rounded(.up))))
    }

    public func facets() async throws -> LibraryFacets {
        let scenes = await store.scenes
        let years = Dictionary(grouping: scenes.compactMap(\.year), by: { $0 }).map { YearFacet(year: $0.key, count: $0.value.count) }.sorted { $0.year > $1.year }
        let data = try JSONSerialization.data(withJSONObject: [
            "years": years.map { ["year": $0.year, "count": $0.count] },
            "studios": [], "tags": [], "performers": [],
            "durationMax": 3600,
            "totals": ["scenes": scenes.count, "matched": scenes.count, "unmatched": 0, "favorites": scenes.filter(\.favorite).count],
        ])
        var facets = try JSON.decoder.decode(LibraryFacets.self, from: data)
        facets = LibraryFacets(years: facets.years, studios: await store.studios, tags: await store.tags,
                               performers: await store.performers, durationMax: 3600, totals: facets.totals)
        return facets
    }

    public func scene(id: Int) async throws -> SceneDetail {
        await pause()
        guard let scene = await store.scenes.first(where: { $0.id == id }) else { throw PulseError.notFound }
        let cast = await store.performers.filter { p in scene.performers.contains { $0.id == p.id } }
        return SceneDetail(scene: scene,
                           description: "A sample scene from the Pulse demo library. Connect your own server to see your real collection, with artwork and metadata matched from ThePornDB and StashDB.",
                           tags: Array(await store.tags.prefix(4)), performers: cast)
    }

    public func editScene(id: Int, _ edit: SceneEdit) async throws -> SceneDetail { try await scene(id: id) }

    public func performers(_ query: PerformerQuery) async throws -> Paged<Performer> {
        await pause()
        var items = await store.performers
        let text = query.text.lowercased()
        if !text.isEmpty { items = items.filter { $0.name.lowercased().contains(text) } }
        if query.favoritesOnly { items = items.filter(\.favorite) }
        if query.sort == .name { items.sort { $0.name < $1.name } }
        return Paged(items: items, total: items.count)
    }

    public func performer(id: Int) async throws -> PerformerDetail {
        guard let p = await store.performers.first(where: { $0.id == id }) else { throw PulseError.notFound }
        let scenes = await store.scenes.filter { s in s.performers.contains { $0.id == id } }
        let json: [String: Any] = ["id": p.id, "name": p.name, "sceneCount": scenes.count, "favorite": p.favorite,
                                   "bio": "Sample performer profile for the demo library.", "aliases": [], "images": [], "links": [String: String]()]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSON.decoder.decode(PerformerDetail.self, from: data).withScenes(scenes)
    }

    public func refreshPerformer(id: Int, source: MetadataProvider?) async throws -> PerformerDetail { try await performer(id: id) }

    public func studios(query: String?, favorites: Bool, page: Int) async throws -> Paged<Studio> {
        var items = await store.studios
        if favorites { items = items.filter(\.favorite) }
        if let query, !query.isEmpty { items = items.filter { $0.name.lowercased().contains(query.lowercased()) } }
        return Paged(items: items, total: items.count)
    }

    public func studio(id: Int) async throws -> StudioDetail {
        guard let s = await store.studios.first(where: { $0.id == id }) else { throw PulseError.notFound }
        let scenes = await store.scenes.filter { $0.studio?.id == id }
        let data = try JSONSerialization.data(withJSONObject: ["id": s.id, "name": s.name, "sceneCount": scenes.count, "favorite": s.favorite])
        return try JSON.decoder.decode(StudioDetail.self, from: data).withScenes(scenes)
    }

    public func tags(query: String?, page: Int) async throws -> Paged<Tag> { Paged(items: await store.tags) }
    public func continueWatching(limit: Int) async throws -> [Video] { Array(await store.scenes.filter(\.isInProgress).prefix(limit)) }
    public func recentlyAdded(limit: Int) async throws -> [Video] { Array(await store.scenes.suffix(limit).reversed()) }

    public func favorites() async throws -> FavoritesBundle {
        FavoritesBundle(scenes: await store.scenes.filter(\.favorite), performers: await store.performers.filter(\.favorite),
                        studios: await store.studios.filter(\.favorite))
    }

    public func watchlist() async throws -> [Video] { await store.scenes.filter(\.watchlist) }

    public func setFavorite(_ type: FavoriteType, id: Int, value: Bool, list: FavoriteList) async throws {
        await store.setFavorite(type, id: id, value: value, list: list)
    }

    public func stream(sceneID: Int) async throws -> StreamInfo {
        await pause()
        return StreamInfo(sceneId: sceneID, primaryURL: Self.sampleStream, proxy: Self.sampleStream, hls: Self.sampleStream, duration: nil)
    }

    public func saveProgress(sceneID: Int, position: Double, duration: Double?, completed: Bool?) async throws {
        await store.setProgress(sceneID, position: position, duration: duration, completed: completed)
    }

    public func clearProgress(sceneID: Int) async throws { await store.clearProgress(sceneID) }
    public func subtitleCues(for track: SubtitleTrack) async throws -> [SubtitleCue] { [] }

    public func pcloudStatus() async throws -> PcloudStatus { await store.pcloud }
    public func pcloudAuthorizeURL(manual: Bool) async throws -> PcloudAuthorizeURL { PcloudAuthorizeURL(url: "https://my.pcloud.com", redirectUri: nil, state: nil) }
    public func pcloudExchange(codeOrURL: String) async throws -> PcloudStatus { await store.pcloud }
    public func pcloudDisconnect(purge: Bool) async throws {}
    public func pcloudFolders(folderID: Int) async throws -> PcloudFolderListing {
        let data = try JSONSerialization.data(withJSONObject: [
            "folderId": folderID, "name": folderID == 0 ? "/" : "Videos", "path": folderID == 0 ? "/" : "/Videos",
            "parentId": folderID == 0 ? NSNull() : 0, "videoCount": 24,
            "folders": [["folderId": 11, "name": "Videos", "path": "/Videos", "selected": true], ["folderId": 12, "name": "Archive", "path": "/Archive", "selected": false]],
        ] as [String: Any])
        return try JSON.decoder.decode(PcloudFolderListing.self, from: data)
    }
    public func scanFolders() async throws -> [ScanFolder] { [ScanFolder(folderId: 11, path: "/Videos", name: "Videos")] }
    public func setScanFolders(_ folders: [ScanFolder]) async throws -> [ScanFolder] { folders }
    public func rescan(full: Bool) async throws -> ScanStatus { .idle }
    public func scanStatus() async throws -> ScanStatus { .idle }

    public func matchStatus() async throws -> MatchJobStatus { .idle }
    public func matchControl(_ action: MatchAction) async throws -> MatchJobStatus { .idle }
    public func unmatched(page: Int) async throws -> Paged<Video> { Paged(items: []) }
    public func searchMatches(sceneID: Int, query: String?) async throws -> MatchResponse {
        try JSON.decoder.decode(MatchResponse.self, from: Data("{\"candidates\":[]}".utf8))
    }
    public func applyMatch(sceneID: Int, candidate: MatchCandidate) async throws -> SceneDetail { try await scene(id: sceneID) }
    public func unmatch(sceneID: Int) async throws -> SceneDetail { try await scene(id: sceneID) }
    public func ignore(sceneID: Int) async throws {}
    public func metadataSources() async throws -> [MetadataSource] {
        [MetadataSource(id: .tpdb, label: "ThePornDB", configured: true, enabled: true, active: true),
         MetadataSource(id: .stashdb, label: "StashDB", configured: true, enabled: true, active: true)]
    }
    public func testProvider(_ provider: MetadataProvider) async throws -> ProviderTest { ProviderTest(ok: true, status: "ok", hint: "Demo mode") }

    public func torboxStatus() async throws -> TorboxStatus {
        try JSON.decoder.decode(TorboxStatus.self, from: Data("{\"linked\":\(await store.torboxLinked),\"planName\":\"Pro\",\"email\":\"demo@pulse.app\"}".utf8))
    }
    public func torboxLink(apiKey: String?) async throws -> TorboxStatus { await store.setTorbox(true); return try await torboxStatus() }
    public func torboxUnlink() async throws { await store.setTorbox(false) }
    public func torboxDownloads(kind: TorboxKind?) async throws -> [TorboxItem] { [] }
    public func torboxAdd(magnetOrURL: String) async throws -> TorboxAddResult { TorboxAddResult(type: .torrents, id: 1, hash: nil, message: "Added (demo)") }
    public func torboxControl(kind: TorboxKind, id: Int, operation: String) async throws {}
    public func torboxStream(kind: TorboxKind, id: Int, fileID: Int) async throws -> TorboxStream { TorboxStream(url: Self.sampleStream, mime: nil, name: nil) }
    public func torboxImport(kind: TorboxKind, ids: [Int]) async throws -> TorboxImportResult { TorboxImportResult(added: 0, seen: 0) }

    public func settings() async throws -> ServerSettings { await store.settings }
    public func updateSettings(_ settings: ServerSettings) async throws -> ServerSettings { await store.setSettings(settings); return settings }
    public func clearData(_ scope: ClearDataScope) async throws {}
}
