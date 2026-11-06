import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE" }

struct EmptyBody: Encodable {}
struct Ack: Decodable { let ok: Bool? }

enum JSON {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}

extension URL {
    /// Joins an `/api/...` path (with optional query) onto a server base URL.
    public func appendingAPI(_ path: String, query: [URLQueryItem] = []) -> URL? {
        guard var parts = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        let base = parts.path.hasSuffix("/") ? String(parts.path.dropLast()) : parts.path
        parts.path = base + (path.hasPrefix("/") ? path : "/" + path)
        parts.queryItems = query.isEmpty ? nil : query
        return parts.url
    }
}

/// Accepts "192.168.1.5:8787", "my.host", "https://pulse.example.com/" and returns a clean base URL.
public func normalizeServerURL(_ raw: String) -> URL? {
    var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return nil }
    if !text.contains("://") {
        let host = text.split(separator: "/").first.map(String.init) ?? text
        let isLocal = host.hasPrefix("localhost") || host.hasPrefix("127.") || host.hasPrefix("192.168.")
            || host.hasPrefix("10.") || host.hasSuffix(".local") || host.hasSuffix(".ts.net")
        text = (isLocal ? "http://" : "https://") + text
    }
    while text.hasSuffix("/") { text.removeLast() }
    guard let url = URL(string: text), let host = url.host, !host.isEmpty,
          url.scheme == "http" || url.scheme == "https" else { return nil }
    return url
}
