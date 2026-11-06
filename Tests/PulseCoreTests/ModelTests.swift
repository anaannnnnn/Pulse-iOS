import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import PulseCore

@Suite("Model decoding")
struct ModelTests {
    let sceneJSON = """
    {"id":7,"title":"Golden Hour","fileName":"golden.mp4","path":"/a/golden.mp4","size":1500000000,
     "duration":1800.5,"width":1920,"height":1080,"date":"2023-04-02","year":2023,"poster":"/api/scenes/7/thumb",
     "thumb":null,"studio":{"id":2,"name":"Atlas"},"performers":[{"id":1,"name":"Ava","image":null}],
     "matchStatus":"matched","matchConfidence":0.93,"favorite":true,
     "progress":{"position":300,"duration":1800,"percent":16.6,"completed":false,"updatedAt":"2026-01-01T00:00:00Z"},
     "addedAt":"2026-01-01T00:00:00Z","source":"pcloud","somethingNew":123}
    """

    @Test func decodesSceneAndIgnoresUnknownKeys() throws {
        let scene = try JSON.decoder.decode(Video.self, from: Data(sceneJSON.utf8))
        #expect(scene.id == 7)
        #expect(scene.studio?.name == "Atlas")
        #expect(scene.favorite)
        #expect(scene.resolutionLabel == "1080p")
        #expect(scene.isInProgress)
        #expect(scene.watchlist == false)
    }

    @Test func progressFractionHandlesPercentScales() {
        #expect(WatchProgress(position: 1, duration: 10, percent: 0.4, completed: false).fraction == 0.4)
        #expect(WatchProgress(position: 1, duration: 10, percent: 40, completed: false).fraction == 0.4)
        #expect(WatchProgress(position: 1, duration: 10, percent: 400, completed: false).fraction == 1)
    }

    @Test func unknownEnumValuesFallBack() throws {
        let json = #"{"id":1,"title":"x","matchStatus":"brand-new-status","source":"somewhere"}"#
        let scene = try JSON.decoder.decode(Video.self, from: Data(json.utf8))
        #expect(scene.matchStatus == .unmatched)
        #expect(scene.source == .pcloud)
    }

    @Test func sceneDetailReusesSceneFields() throws {
        let json = """
        {"id":3,"title":"T","fileName":"t.mp4","path":"/t","size":1,"description":"d","tags":[{"id":1,"name":"Cinematic","sceneCount":4}],
         "performers":[{"id":9,"name":"Mira","sceneCount":3,"favorite":false}],"tpdb":{"id":"abc","type":"scene","url":null}}
        """
        let detail = try JSON.decoder.decode(SceneDetail.self, from: Data(json.utf8))
        #expect(detail.id == 3)
        #expect(detail.tags.first?.name == "Cinematic")
        #expect(detail.performers.first?.name == "Mira")
        #expect(detail.tpdb?.id == "abc")
    }

    @Test func homeRailsSplitScenesAndPerformers() throws {
        let json = """
        {"hero":[],"rails":[
          {"id":"recent","title":"Recent","kind":"scenes","items":[\(sceneJSON)]},
          {"id":"top-performers","title":"Top","kind":"performers","items":[{"id":4,"name":"Kai","sceneCount":2,"favorite":false}]}]}
        """
        let feed = try JSON.decoder.decode(HomeFeed.self, from: Data(json.utf8))
        #expect(feed.rails[0].scenes.count == 1)
        #expect(feed.rails[1].performers.first?.name == "Kai")
    }

    @Test func pagedHasMore() throws {
        let json = #"{"items":[],"page":1,"pageSize":40,"total":90,"totalPages":3}"#
        let page = try JSON.decoder.decode(Paged<Video>.self, from: Data(json.utf8))
        #expect(page.hasMore)
    }
}

@Suite("Streaming")
struct StreamingTests {
    func info() throws -> StreamInfo {
        let json = """
        {"sceneId":1,"primary":{"url":"https://cdn/orig.mp4","type":"mp4","mime":null,"label":"Original"},
         "alternatives":[{"url":"https://cdn/720.mp4","type":"mp4","label":"720p","width":1280,"height":720,"bitrate":null},
                         {"url":"https://cdn/1080.mp4","type":"mp4","label":"1080p","width":1920,"height":1080,"bitrate":null}],
         "hls":"https://cdn/master.m3u8","proxy":"/api/scenes/1/proxy","subtitles":[],"thumbnails":null,"duration":100}
        """
        return try JSON.decoder.decode(StreamInfo.self, from: Data(json.utf8))
    }

    @Test func prefersRequestedQualityThenFallsBack() throws {
        let urls = try info().candidates(preferring: .p720, preferHLS: false)
        #expect(urls.first == "https://cdn/720.mp4")
        #expect(urls.last == "/api/scenes/1/proxy")
        #expect(Set(urls).count == urls.count)
    }

    @Test func autoPrefersHLS() throws {
        #expect(try info().candidates(preferring: .auto, preferHLS: false).first == "https://cdn/master.m3u8")
    }

    @Test func originalStartsWithPrimary() throws {
        #expect(try info().candidates(preferring: .original, preferHLS: false).first == "https://cdn/orig.mp4")
    }
}

@Suite("Support")
struct SupportTests {
    @Test func webVTTParsesCuesAndStripsTags() {
        let vtt = "WEBVTT\n\n1\n00:00:01.000 --> 00:00:03.500\n<i>Hello</i> &amp; welcome\n\n00:01:00,000 --> 00:01:02,000 align:start\nSecond\nline\n"
        let cues = WebVTT.parse(vtt)
        #expect(cues.count == 2)
        #expect(cues[0].text == "Hello & welcome")
        #expect(cues[1].start == 60)
        #expect(WebVTT.cue(at: 2, in: cues)?.text == "Hello & welcome")
        #expect(WebVTT.cue(at: 10, in: cues) == nil)
        #expect(WebVTT.cue(at: 61, in: cues)?.text == "Second\nline")
    }

    @Test func serverURLNormalisation() {
        #expect(normalizeServerURL("192.168.1.5:8787")?.absoluteString == "http://192.168.1.5:8787")
        #expect(normalizeServerURL("pulse.example.com/")?.absoluteString == "https://pulse.example.com")
        #expect(normalizeServerURL("https://x.test///")?.absoluteString == "https://x.test")
        #expect(normalizeServerURL("   ") == nil)
        #expect(normalizeServerURL("ftp://x.test") == nil)
    }

    @Test func apiURLJoinKeepsBasePath() {
        let base = URL(string: "https://host.test/pulse")!
        #expect(base.appendingAPI("/api/home")?.absoluteString == "https://host.test/pulse/api/home")
        let q = base.appendingAPI("/api/library", query: [.init(name: "q", value: "a b")])
        #expect(q?.absoluteString == "https://host.test/pulse/api/library?q=a%20b")
    }

    @Test func libraryQueryBuildsItemsAndCountsFilters() {
        var q = LibraryQuery()
        q.text = " night "
        q.tagIDs = [1, 2]
        q.yearFrom = 2018; q.yearTo = 2021
        q.favoritesOnly = true
        q.watched = .inprogress
        let items = Dictionary(uniqueKeysWithValues: q.queryItems.map { ($0.name, $0.value ?? "") })
        #expect(items["q"] == "night")
        #expect(items["tags"] == "1,2")
        #expect(items["year"] == "2018-2021")
        #expect(items["watched"] == "inprogress")
        #expect(q.activeFilterCount == 4)
        q.clearFilters()
        #expect(q.activeFilterCount == 0)
        #expect(q.text == " night ")
    }

    @Test func formatting() {
        #expect(Format.clock(3725) == "1:02:05")
        #expect(Format.clock(95) == "1:35")
        #expect(Format.clock(nil) == "0:00")
        #expect(Format.runtime(3725) == "1h 2m")
        #expect(Format.runtime(1500) == "25 min")
        #expect(Format.bytes(1_500_000_000) == "1.5 GB")
    }

    @Test func errorMapping() {
        let resp = HTTPURLResponse(url: URL(string: "https://x.test")!, statusCode: 429, httpVersion: nil, headerFields: ["Retry-After": "60"])
        #expect(PulseClient.mapError(status: 423, data: Data(), response: nil) == .locked)
        #expect(PulseClient.mapError(status: 429, data: Data(), response: resp) == .rateLimited(retryAfter: 60))
        let bad = Data(#"{"error":{"code":"bad_login","message":"Wrong email or password. 4 tries left."}}"#.utf8)
        #expect(PulseClient.mapError(status: 401, data: bad, response: nil) == .badCredentials("Wrong email or password. 4 tries left."))
        let pc = Data(#"{"error":{"code":"pcloud_not_connected","message":"x"}}"#.utf8)
        #expect(PulseClient.mapError(status: 409, data: pc, response: nil) == .pcloudNotConnected)
    }
}

@Suite("Stores")
@MainActor
struct StoreTests {
    @Test func demoSessionIsSignedInImmediately() async {
        let defaults = UserDefaults(suiteName: "pulse.tests.\(UUID().uuidString)")!
        let session = AppSession(defaults: defaults)
        #expect(session.serverURL == PulseDefaults.serverURL)
        session.enterDemo()
        #expect(session.phase == .unlocked)
        await session.signOut()
        #expect(session.phase == .signedOut)
        #expect(!session.isDemo)
    }

    @Test func signInRejectsEmptyFields() async {
        let defaults = UserDefaults(suiteName: "pulse.tests.\(UUID().uuidString)")!
        let session = AppSession(defaults: defaults)
        #expect(await session.signIn(email: " ", password: "") == false)
        #expect(session.authError != nil)
    }

    @Test func customServerOverridesDefault() async {
        let defaults = UserDefaults(suiteName: "pulse.tests.\(UUID().uuidString)")!
        let session = AppSession(defaults: defaults)
        defaults.set("http://192.168.1.5:8787", forKey: "pulse.serverURL")
        #expect(session.serverURL.absoluteString == "http://192.168.1.5:8787")
        #expect(session.usesCustomServer)
    }

    @Test func libraryStoreLoadsAndPaginates() async {
        let store = LibraryStore(api: DemoClient())
        await store.reload()
        #expect(!store.scenes.isEmpty)
        #expect(store.total >= store.scenes.count)
    }

    @Test func favoritesHubIsOptimistic() async throws {
        let api = DemoClient()
        let hub = FavoritesHub(api: api)
        let scene = try await api.library(LibraryQuery()).items.first { !$0.favorite }!
        #expect(!hub.isFavorite(scene))
        await hub.toggle(scene)
        #expect(hub.isFavorite(scene))
        await hub.toggle(scene)
        #expect(!hub.isFavorite(scene))
    }

    @Test func playbackFallsBackThroughSources() async throws {
        let api = DemoClient()
        let scene = try await api.library(LibraryQuery()).items[0]
        let model = PlaybackModel(scene: scene, api: api)
        await model.prepare()
        #expect(model.phase == .ready)
        #expect(model.currentURL != nil)
    }
}
