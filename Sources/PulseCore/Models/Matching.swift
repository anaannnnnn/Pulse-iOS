import Foundation

public struct MatchCandidate: Codable, Hashable, Sendable, Identifiable {
    public let source: MetadataProvider?
    public let tpdbId: String
    public let type: SceneKind?
    public let title: String
    public let date: String?
    public let studio: String?
    public let performers: [String]
    public let poster: String?
    public let duration: Double?
    public let url: String?
    public let confidence: Double
    public let matchedBy: String?

    public var id: String { (source?.rawValue ?? "tpdb") + ":" + tpdbId }

    enum CodingKeys: String, CodingKey {
        case source, tpdbId, type, title, date, studio, performers, poster, duration, url, confidence, matchedBy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        source = try c.decodeIfPresent(MetadataProvider.self, forKey: .source)
        tpdbId = try c.decodeIfPresent(String.self, forKey: .tpdbId) ?? ""
        type = try c.decodeIfPresent(SceneKind.self, forKey: .type)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date)
        studio = try c.decodeIfPresent(String.self, forKey: .studio)
        performers = try c.decodeIfPresent([String].self, forKey: .performers) ?? []
        poster = try c.decodeIfPresent(String.self, forKey: .poster)
        duration = try c.decodeIfPresent(Double.self, forKey: .duration)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        matchedBy = try c.decodeIfPresent(String.self, forKey: .matchedBy)
    }
}

public struct MatchResponse: Codable, Hashable, Sendable {
    public let candidates: [MatchCandidate]
    public let applied: MatchCandidate?

    enum CodingKeys: String, CodingKey { case candidates, applied }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        candidates = try c.decodeIfPresent([MatchCandidate].self, forKey: .candidates) ?? []
        applied = try c.decodeIfPresent(MatchCandidate.self, forKey: .applied)
    }
}

public struct MatchJobStatus: Codable, Hashable, Sendable {
    public enum State: String, LenientEnum, Hashable {
        case idle, running
        public static var fallback: State { .idle }
    }
    public struct Current: Codable, Hashable, Sendable {
        public let sceneId: Int
        public let title: String
    }
    public let state: State
    public let queued: Int
    public let processed: Int
    public let matched: Int
    public let failed: Int
    public let unmatched: Int
    public let current: Current?
    public let paused: Bool
    public let total: Int
    public let rate: Double
    public let etaSeconds: Double?
    public let lastError: String?

    enum CodingKeys: String, CodingKey {
        case state, queued, processed, matched, failed, unmatched, current, paused, total, rate, etaSeconds, lastError
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(State.self, forKey: .state) ?? .idle
        queued = try c.decodeIfPresent(Int.self, forKey: .queued) ?? 0
        processed = try c.decodeIfPresent(Int.self, forKey: .processed) ?? 0
        matched = try c.decodeIfPresent(Int.self, forKey: .matched) ?? 0
        failed = try c.decodeIfPresent(Int.self, forKey: .failed) ?? 0
        unmatched = try c.decodeIfPresent(Int.self, forKey: .unmatched) ?? 0
        current = try c.decodeIfPresent(Current.self, forKey: .current)
        paused = try c.decodeIfPresent(Bool.self, forKey: .paused) ?? false
        total = try c.decodeIfPresent(Int.self, forKey: .total) ?? 0
        rate = try c.decodeIfPresent(Double.self, forKey: .rate) ?? 0
        etaSeconds = try c.decodeIfPresent(Double.self, forKey: .etaSeconds)
        lastError = try c.decodeIfPresent(String.self, forKey: .lastError)
    }

    public static let idle = MatchJobStatus(idle: ())

    private init(idle: Void) {
        state = .idle; queued = 0; processed = 0; matched = 0; failed = 0; unmatched = 0
        current = nil; paused = false; total = 0; rate = 0; etaSeconds = nil; lastError = nil
    }

    public var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(processed) / Double(total), 1)
    }
}

public enum MatchAction: Sendable {
    case queue(sceneIDs: [Int]?, all: Bool, priority: Bool)
    case pause, resume, cancel
    case retryUnmatched
}

public struct MetadataSource: Codable, Hashable, Sendable, Identifiable {
    public let id: MetadataProvider
    public let label: String
    public let configured: Bool
    public let enabled: Bool
    public let active: Bool
}

public struct MetadataSources: Codable, Hashable, Sendable {
    public let sources: [MetadataSource]
}

public struct ProviderTest: Codable, Hashable, Sendable {
    public let ok: Bool
    public let status: String?
    public let hint: String?
}
