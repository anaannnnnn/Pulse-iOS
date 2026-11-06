import XCTest
import Foundation
@testable import PulseCore

/// Runs against a real Pulse server. Skipped unless PULSE_LIVE_URL, PULSE_LIVE_EMAIL and PULSE_LIVE_PASSWORD are set.
final class LiveServerTests: XCTestCase {
    func testEveryReadEndpointDecodes() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let raw = env["PULSE_LIVE_URL"], let url = URL(string: raw),
              let email = env["PULSE_LIVE_EMAIL"], let password = env["PULSE_LIVE_PASSWORD"] else {
            throw XCTSkip("live server not configured")
        }
        let api = PulseClient(baseURL: url)
        var failures: [String] = []
        func check<T>(_ name: String, _ body: () async throws -> T) async -> T? {
            do { let v = try await body(); print("ok   \(name)"); return v }
            catch { failures.append("\(name): \(error)"); print("FAIL \(name): \(error)"); return nil }
        }
        _ = await check("health") { try await api.health() }
        _ = await check("session(locked)") { try await api.session() }
        await check("signIn") { try await api.signIn(email: email, password: password) }
        let s = await check("session") { try await api.session() }
        XCTAssertEqual(s?.locked, false)
        _ = await check("home") { try await api.home() }
        let lib = await check("library") { try await api.library(LibraryQuery()) }
        _ = await check("facets") { try await api.facets() }
        _ = await check("performers") { try await api.performers(PerformerQuery()) }
        _ = await check("studios") { try await api.studios(query: nil, favorites: false, page: 1) }
        _ = await check("tags") { try await api.tags(query: nil, page: 1) }
        _ = await check("continueWatching") { try await api.continueWatching(limit: 12) }
        _ = await check("recentlyAdded") { try await api.recentlyAdded(limit: 12) }
        _ = await check("favorites") { try await api.favorites() }
        _ = await check("watchlist") { try await api.watchlist() }
        if let id = lib?.items.first?.id {
            _ = await check("scene") { try await api.scene(id: id) }
            _ = await check("stream") { try await api.stream(sceneID: id) }
        }
        if let p = (await check("performers2") { try await api.performers(PerformerQuery()) })?.items.first {
            _ = await check("performer") { try await api.performer(id: p.id) }
        }
        if let st = (await check("studios2") { try await api.studios(query: nil, favorites: false, page: 1) })?.items.first {
            _ = await check("studio") { try await api.studio(id: st.id) }
        }
        _ = await check("pcloudStatus") { try await api.pcloudStatus() }
        _ = await check("scanFolders") { try await api.scanFolders() }
        _ = await check("scanStatus") { try await api.scanStatus() }
        _ = await check("matchStatus") { try await api.matchStatus() }
        _ = await check("unmatched") { try await api.unmatched(page: 1) }
        _ = await check("metadataSources") { try await api.metadataSources() }
        _ = await check("torboxStatus") { try await api.torboxStatus() }
        _ = await check("settings") { try await api.settings() }
        _ = await check("pcloudFolders") { try await api.pcloudFolders(folderID: 0) }
        await check("signOut") { try await api.signOut() }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
