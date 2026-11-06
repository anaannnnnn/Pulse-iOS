import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP implementation of `PulseAPI`. Auth is the server's `pulse_auth` cookie, kept by the session's cookie storage.
public final class PulseClient: PulseAPI, @unchecked Sendable {
    public let baseURL: URL
    private let session: URLSession
    private let tokenStore: SessionTokenStore
    private let tokenLock = NSLock()
    private var token: String?

    public init(baseURL: URL, session: URLSession? = nil, tokenStore: SessionTokenStore? = nil) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore ?? SessionTokenStore(server: baseURL)
        self.token = self.tokenStore.load()
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpCookieStorage = HTTPCookieStorage.shared
            config.httpCookieAcceptPolicy = .always
            config.httpShouldSetCookies = true
            config.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: config)
        }
    }

    /// The session token, sent as a bearer header (the cookie alone is not reliable on every OS).
    public var sessionToken: String? {
        tokenLock.lock(); defer { tokenLock.unlock() }
        return token
    }

    private func setToken(_ value: String?) {
        tokenLock.lock(); token = value; tokenLock.unlock()
        tokenStore.save(value)
    }

    /// Resolves a server path (or absolute URL) for images and video, adding the token the server accepts as `?pt=`.
    public func absoluteURL(_ path: String) -> URL? {
        let url = path.hasPrefix("http://") || path.hasPrefix("https://") ? URL(string: path) : baseURL.appendingAPI(path)
        return url.map { $0.addingSessionToken(sessionToken, forServer: baseURL) }
    }

    // MARK: Core request plumbing

    private func request(_ method: HTTPMethod, _ path: String, query: [URLQueryItem] = [], body: Data? = nil) throws -> URLRequest {
        guard let url = baseURL.appendingAPI(path, query: query) else { throw PulseError.invalidServerURL }
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = sessionToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func perform(_ req: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch let error as URLError where error.code == .cancelled {
            throw PulseError.cancelled
        } catch is CancellationError {
            throw PulseError.cancelled
        } catch {
            throw PulseError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw PulseError.offline }
        guard (200..<300).contains(http.statusCode) else { throw Self.mapError(status: http.statusCode, data: data, response: http) }
        return data
    }

    static func mapError(status: Int, data: Data, response: HTTPURLResponse?) -> PulseError {
        let envelope = try? JSON.decoder.decode(ServerErrorEnvelope.self, from: data)
        let code = envelope?.error?.code ?? ""
        let message = envelope?.error?.message ?? HTTPURLResponse.localizedString(forStatusCode: status)
        switch (status, code) {
        case (423, _), (_, "locked"): return .locked
        case (401, _): return .badCredentials(message)
        case (429, _):
            let wait = response?.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            return .rateLimited(retryAfter: wait)
        case (404, _): return .notFound
        case (409, "pcloud_not_connected"): return .pcloudNotConnected
        case (409, "torbox_not_linked"): return .torboxNotLinked
        case (502, _): return .upstream(message)
        case (400, _), (422, _): return .badRequest(message)
        default: return .server(status: status, message: message)
        }
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = [], as: T.Type = T.self) async throws -> T {
        try decode(try await perform(try request(.get, path, query: query)))
    }

    private func send<T: Decodable, B: Encodable>(_ method: HTTPMethod, _ path: String, body: B, as: T.Type = T.self) async throws -> T {
        let data = try JSON.encoder.encode(body)
        return try decode(try await perform(try request(method, path, body: data)))
    }

    private func sendVoid<B: Encodable>(_ method: HTTPMethod, _ path: String, body: B) async throws {
        let data = try JSON.encoder.encode(body)
        _ = try await perform(try request(method, path, body: data))
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do { return try JSON.decoder.decode(T.self, from: data) }
        catch { throw PulseError.decoding(String(describing: error).prefix(160).description) }
    }

    // MARK: Session

    public func health() async throws -> HealthInfo { try await get("/api/health") }
    public func session() async throws -> SessionState { try await get("/api/session") }

    public func signIn(email: String, password: String) async throws {
        struct Body: Encodable { let email: String; let password: String }
        struct Reply: Decodable { let token: String? }
        setToken(nil)
        let reply: Reply = try await send(.post, "/api/session/login", body: Body(email: email, password: password))
        setToken(reply.token)
    }

    public func signOut() async throws {
        defer { setToken(nil) }
        try await sendVoid(.post, "/api/session/lock", body: EmptyBody())
    }

    public func changePassword(current: String, new: String) async throws {
        struct Body: Encodable { let password: String; let currentPassword: String }
        try await sendVoid(.post, "/api/settings/password", body: Body(password: new, currentPassword: current))
    }

    // MARK: Browse

    public func home() async throws -> HomeFeed { try await get("/api/home") }
    public func library(_ query: LibraryQuery) async throws -> Paged<Video> { try await get("/api/library", query: query.queryItems) }
    public func facets() async throws -> LibraryFacets { try await get("/api/library/facets") }
    public func scene(id: Int) async throws -> SceneDetail { try await get("/api/scenes/\(id)") }
    public func editScene(id: Int, _ edit: SceneEdit) async throws -> SceneDetail { try await send(.patch, "/api/scenes/\(id)", body: edit) }
    public func performers(_ query: PerformerQuery) async throws -> Paged<Performer> { try await get("/api/performers", query: query.queryItems) }
    public func performer(id: Int) async throws -> PerformerDetail { try await get("/api/performers/\(id)") }

    public func refreshPerformer(id: Int, source: MetadataProvider?) async throws -> PerformerDetail {
        struct Body: Encodable { let source: String? }
        return try await send(.post, "/api/performers/\(id)/refresh", body: Body(source: source?.rawValue))
    }

    public func studios(query: String?, favorites: Bool, page: Int) async throws -> Paged<Studio> {
        var items = [URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "pageSize", value: "60")]
        if let query, !query.isEmpty { items.append(.init(name: "q", value: query)) }
        if favorites { items.append(.init(name: "favorites", value: "true")) }
        return try await get("/api/studios", query: items)
    }

    public func studio(id: Int) async throws -> StudioDetail { try await get("/api/studios/\(id)") }

    public func tags(query: String?, page: Int) async throws -> Paged<Tag> {
        var items = [URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "pageSize", value: "100")]
        if let query, !query.isEmpty { items.append(.init(name: "q", value: query)) }
        return try await get("/api/tags", query: items)
    }

    public func continueWatching(limit: Int) async throws -> [Video] {
        let list: ItemList<Video> = try await get("/api/continue-watching", query: [.init(name: "limit", value: "\(limit)")])
        return list.items
    }

    public func recentlyAdded(limit: Int) async throws -> [Video] {
        let list: ItemList<Video> = try await get("/api/recently-added", query: [.init(name: "limit", value: "\(limit)")])
        return list.items
    }

    // MARK: Favourites

    public func favorites() async throws -> FavoritesBundle { try await get("/api/favorites") }

    public func watchlist() async throws -> [Video] {
        let list: ItemList<Video> = try await get("/api/watchlist")
        return list.items
    }

    public func setFavorite(_ type: FavoriteType, id: Int, value: Bool, list: FavoriteList) async throws {
        struct Body: Encodable { let type: String; let id: Int; let favorite: Bool; let list: String }
        try await sendVoid(.post, "/api/favorites/toggle", body: Body(type: type.rawValue, id: id, favorite: value, list: list.rawValue))
    }

    // MARK: Playback

    public func stream(sceneID: Int) async throws -> StreamInfo { try await get("/api/scenes/\(sceneID)/stream") }

    public func saveProgress(sceneID: Int, position: Double, duration: Double?, completed: Bool?) async throws {
        struct Body: Encodable { let position: Double; let duration: Double?; let completed: Bool? }
        try await sendVoid(.put, "/api/scenes/\(sceneID)/progress", body: Body(position: position, duration: duration, completed: completed))
    }

    public func clearProgress(sceneID: Int) async throws {
        _ = try await perform(try request(.delete, "/api/scenes/\(sceneID)/progress"))
    }

    public func subtitleCues(for track: SubtitleTrack) async throws -> [SubtitleCue] {
        guard let url = absoluteURL(track.url) else { throw PulseError.invalidServerURL }
        var subtitleRequest = URLRequest(url: url)
        if let token = sessionToken { subtitleRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let data = try await perform(subtitleRequest)
        return WebVTT.parse(String(decoding: data, as: UTF8.self))
    }

    // MARK: pCloud

    public func pcloudStatus() async throws -> PcloudStatus { try await get("/api/pcloud/status") }

    public func pcloudAuthorizeURL(manual: Bool) async throws -> PcloudAuthorizeURL {
        try await get("/api/pcloud/authorize-url", query: manual ? [.init(name: "manual", value: "1")] : [])
    }

    public func pcloudExchange(codeOrURL: String) async throws -> PcloudStatus {
        struct Body: Encodable { let code: String?; let callbackUrl: String? }
        let isURL = codeOrURL.contains("://")
        return try await send(.post, "/api/pcloud/exchange", body: Body(code: isURL ? nil : codeOrURL, callbackUrl: isURL ? codeOrURL : nil))
    }

    public func pcloudDisconnect(purge: Bool) async throws {
        struct Body: Encodable { let purge: Bool }
        try await sendVoid(.post, "/api/pcloud/disconnect", body: Body(purge: purge))
    }

    public func pcloudFolders(folderID: Int) async throws -> PcloudFolderListing {
        try await get("/api/pcloud/folders", query: [.init(name: "folderId", value: "\(folderID)")])
    }

    public func scanFolders() async throws -> [ScanFolder] {
        let result: ScanFolders = try await get("/api/pcloud/scan-folders")
        return result.folders
    }

    public func setScanFolders(_ folders: [ScanFolder]) async throws -> [ScanFolder] {
        struct Body: Encodable { let folders: [ScanFolder] }
        let result: ScanFolders = try await send(.put, "/api/pcloud/scan-folders", body: Body(folders: folders))
        return result.folders
    }

    public func rescan(full: Bool) async throws -> ScanStatus {
        struct Body: Encodable { let full: Bool; let autoMatch: Bool }
        return try await send(.post, "/api/pcloud/rescan", body: Body(full: full, autoMatch: true))
    }

    public func scanStatus() async throws -> ScanStatus { try await get("/api/pcloud/scan") }

    // MARK: Matching

    public func matchStatus() async throws -> MatchJobStatus { try await get("/api/match/status") }

    public func matchControl(_ action: MatchAction) async throws -> MatchJobStatus {
        switch action {
        case .pause: return try await send(.post, "/api/match/pause", body: EmptyBody())
        case .resume: return try await send(.post, "/api/match/resume", body: EmptyBody())
        case .cancel: return try await send(.post, "/api/match/cancel", body: EmptyBody())
        case .retryUnmatched:
            struct Body: Encodable { let includeIgnored: Bool }
            return try await send(.post, "/api/match/retry-unmatched", body: Body(includeIgnored: false))
        case .queue(let ids, let all, let priority):
            struct Body: Encodable { let sceneIds: [Int]?; let all: Bool; let priority: Bool }
            return try await send(.post, "/api/match/queue", body: Body(sceneIds: ids, all: all, priority: priority))
        }
    }

    public func unmatched(page: Int) async throws -> Paged<Video> {
        try await get("/api/match/unmatched", query: [.init(name: "page", value: "\(page)"), .init(name: "pageSize", value: "40")])
    }

    public func searchMatches(sceneID: Int, query: String?) async throws -> MatchResponse {
        struct Body: Encodable { let query: String?; let apply: Bool }
        return try await send(.post, "/api/scenes/\(sceneID)/match", body: Body(query: query, apply: false))
    }

    public func applyMatch(sceneID: Int, candidate: MatchCandidate) async throws -> SceneDetail {
        struct Body: Encodable { let tpdbId: String; let type: String?; let source: String }
        struct Reply: Decodable { let scene: SceneDetail }
        let reply: Reply = try await send(.post, "/api/scenes/\(sceneID)/match",
                                          body: Body(tpdbId: candidate.tpdbId, type: candidate.type?.rawValue,
                                                     source: (candidate.source ?? .tpdb).rawValue))
        return reply.scene
    }

    public func unmatch(sceneID: Int) async throws -> SceneDetail { try await send(.post, "/api/scenes/\(sceneID)/unmatch", body: EmptyBody()) }

    public func ignore(sceneID: Int) async throws { try await sendVoid(.post, "/api/scenes/\(sceneID)/ignore", body: EmptyBody()) }

    public func metadataSources() async throws -> [MetadataSource] {
        let result: MetadataSources = try await get("/api/metadata/sources")
        return result.sources
    }

    public func testProvider(_ provider: MetadataProvider) async throws -> ProviderTest {
        try await get(provider == .tpdb ? "/api/tpdb/test" : "/api/stashdb/test")
    }

    // MARK: TorBox

    public func torboxStatus() async throws -> TorboxStatus { try await get("/api/torbox/status") }

    public func torboxLink(apiKey: String?) async throws -> TorboxStatus {
        struct Body: Encodable { let apiKey: String? }
        return try await send(.put, "/api/torbox/link", body: Body(apiKey: apiKey))
    }

    public func torboxUnlink() async throws { _ = try await perform(try request(.delete, "/api/torbox/link")) }

    public func torboxDownloads(kind: TorboxKind?) async throws -> [TorboxItem] {
        let list: ItemList<TorboxItem> = try await get("/api/torbox/downloads", query: [.init(name: "type", value: kind?.rawValue ?? "all")])
        return list.items
    }

    public func torboxAdd(magnetOrURL: String) async throws -> TorboxAddResult {
        struct Body: Encodable { let magnet: String?; let url: String? }
        let isMagnet = magnetOrURL.lowercased().hasPrefix("magnet:")
        return try await send(.post, "/api/torbox/add", body: Body(magnet: isMagnet ? magnetOrURL : nil, url: isMagnet ? nil : magnetOrURL))
    }

    public func torboxControl(kind: TorboxKind, id: Int, operation: String) async throws {
        struct Body: Encodable { let operation: String }
        try await sendVoid(.post, "/api/torbox/downloads/\(kind.rawValue)/\(id)/control", body: Body(operation: operation))
    }

    public func torboxStream(kind: TorboxKind, id: Int, fileID: Int) async throws -> TorboxStream {
        try await get("/api/torbox/stream", query: [.init(name: "type", value: kind.rawValue), .init(name: "id", value: "\(id)"), .init(name: "fileId", value: "\(fileID)")])
    }

    public func torboxImport(kind: TorboxKind, ids: [Int]) async throws -> TorboxImportResult {
        struct Body: Encodable { let type: String; let ids: [Int]; let autoMatch: Bool }
        return try await send(.post, "/api/torbox/import", body: Body(type: kind.rawValue, ids: ids, autoMatch: true))
    }

    // MARK: Settings

    public func settings() async throws -> ServerSettings { try await get("/api/settings") }
    public func updateSettings(_ settings: ServerSettings) async throws -> ServerSettings { try await send(.put, "/api/settings", body: settings) }

    public func clearData(_ scope: ClearDataScope) async throws {
        struct Body: Encodable { let what: String }
        try await sendVoid(.post, "/api/data/clear", body: Body(what: scope.rawValue))
    }
}
