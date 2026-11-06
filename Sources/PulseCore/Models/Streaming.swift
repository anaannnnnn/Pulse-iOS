import Foundation

public struct StreamLink: Codable, Hashable, Sendable {
    public enum Kind: String, LenientEnum, Hashable {
        case mp4, hls, other
        public static var fallback: Kind { .other }
    }
    public let url: String
    public let type: Kind
    public let mime: String?
    public let label: String?
}

public struct StreamAlternative: Codable, Hashable, Sendable, Identifiable {
    public let url: String
    public let type: StreamLink.Kind
    public let label: String
    public let width: Int?
    public let height: Int?
    public let bitrate: Int?
    public var id: String { url }
}

public struct SubtitleTrack: Codable, Hashable, Sendable, Identifiable {
    public let label: String
    public let lang: String?
    public let url: String
    public let format: String?
    public var id: String { url }
}

public struct StreamInfo: Codable, Hashable, Sendable {
    public let sceneId: Int
    public let expiresAt: String?
    public let primary: StreamLink
    public let alternatives: [StreamAlternative]
    public let hls: String?
    public let proxy: String
    public let subtitles: [SubtitleTrack]
    public let thumbnails: String?
    public let duration: Double?

    enum CodingKeys: String, CodingKey {
        case sceneId, expiresAt, primary, alternatives, hls, proxy, subtitles, thumbnails, duration
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sceneId = try c.decode(Int.self, forKey: .sceneId)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        primary = try c.decode(StreamLink.self, forKey: .primary)
        alternatives = try c.decodeIfPresent([StreamAlternative].self, forKey: .alternatives) ?? []
        hls = try c.decodeIfPresent(String.self, forKey: .hls)
        proxy = try c.decode(String.self, forKey: .proxy)
        subtitles = try c.decodeIfPresent([SubtitleTrack].self, forKey: .subtitles) ?? []
        thumbnails = try c.decodeIfPresent(String.self, forKey: .thumbnails)
        duration = try c.decodeIfPresent(Double.self, forKey: .duration)
    }

    public init(sceneId: Int, primaryURL: String, proxy: String, hls: String? = nil,
                alternatives: [StreamAlternative] = [], subtitles: [SubtitleTrack] = [], duration: Double? = nil) {
        self.sceneId = sceneId; self.expiresAt = nil
        self.primary = StreamLink(url: primaryURL, type: .mp4, mime: nil, label: "Original")
        self.alternatives = alternatives; self.hls = hls; self.proxy = proxy
        self.subtitles = subtitles; self.thumbnails = nil; self.duration = duration
    }

    /// Ordered playback candidates for a quality preference: try each until one plays.
    public func candidates(preferring quality: QualityPreference, preferHLS: Bool) -> [String] {
        var urls: [String] = []
        func add(_ value: String?) { if let value, !value.isEmpty, !urls.contains(value) { urls.append(value) } }

        let wanted = Int(quality.rawValue.dropLast()) // "1080p" -> 1080
        if let wanted, let match = alternatives.min(by: { abs(($0.height ?? 0) - wanted) < abs(($1.height ?? 0) - wanted) }) {
            add(match.url)
        }
        if preferHLS || quality == .auto { add(hls) }
        add(primary.url)
        add(hls)
        add(proxy)
        return urls
    }
}

/// Resolved WebVTT cue, used by the in-app subtitle overlay.
public struct SubtitleCue: Hashable, Sendable {
    public let start: Double
    public let end: Double
    public let text: String
}
