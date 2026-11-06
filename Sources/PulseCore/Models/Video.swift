import Foundation

public struct WatchProgress: Codable, Hashable, Sendable {
    public var position: Double
    public var duration: Double?
    public var percent: Double
    public var completed: Bool
    public var updatedAt: String?

    public init(position: Double, duration: Double?, percent: Double, completed: Bool, updatedAt: String? = nil) {
        self.position = position; self.duration = duration; self.percent = percent
        self.completed = completed; self.updatedAt = updatedAt
    }

    /// 0...1 fraction regardless of whether the server sent 0...1 or 0...100.
    public var fraction: Double {
        let value = percent > 1 ? percent / 100 : percent
        return min(max(value, 0), 1)
    }
}

public struct Video: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let fileName: String
    public let path: String
    public let size: Int64
    public let duration: Double?
    public let width: Int?
    public let height: Int?
    public let date: String?
    public let year: Int?
    public let poster: String?
    public let thumb: String?
    public let studio: StudioRef?
    public let performers: [PerformerRef]
    public let matchStatus: MatchStatus
    public let matchConfidence: Double?
    public let matchSource: MetadataProvider?
    public var favorite: Bool
    public var watchlist: Bool
    public var progress: WatchProgress?
    public let addedAt: String?
    public let source: SceneSource

    enum CodingKeys: String, CodingKey {
        case id, title, fileName, path, size, duration, width, height, date, year, poster, thumb
        case studio, performers, matchStatus, matchConfidence, matchSource, favorite, watchlist
        case progress, addedAt, source
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        fileName = try c.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        size = try c.decodeIfPresent(Int64.self, forKey: .size) ?? 0
        duration = try c.decodeIfPresent(Double.self, forKey: .duration)
        width = try c.decodeIfPresent(Int.self, forKey: .width)
        height = try c.decodeIfPresent(Int.self, forKey: .height)
        date = try c.decodeIfPresent(String.self, forKey: .date)
        year = try c.decodeIfPresent(Int.self, forKey: .year)
        poster = try c.decodeIfPresent(String.self, forKey: .poster)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        studio = try c.decodeIfPresent(StudioRef.self, forKey: .studio)
        performers = try c.decodeIfPresent([PerformerRef].self, forKey: .performers) ?? []
        matchStatus = try c.decodeIfPresent(MatchStatus.self, forKey: .matchStatus) ?? .unmatched
        matchConfidence = try c.decodeIfPresent(Double.self, forKey: .matchConfidence)
        matchSource = try c.decodeIfPresent(MetadataProvider.self, forKey: .matchSource)
        favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        watchlist = try c.decodeIfPresent(Bool.self, forKey: .watchlist) ?? false
        progress = try c.decodeIfPresent(WatchProgress.self, forKey: .progress)
        addedAt = try c.decodeIfPresent(String.self, forKey: .addedAt)
        source = try c.decodeIfPresent(SceneSource.self, forKey: .source) ?? .pcloud
    }

    public init(id: Int, title: String, duration: Double? = nil, width: Int? = 1920, height: Int? = 1080,
                year: Int? = nil, poster: String? = nil, studio: StudioRef? = nil,
                performers: [PerformerRef] = [], progress: WatchProgress? = nil,
                favorite: Bool = false, matchStatus: MatchStatus = .matched) {
        self.id = id; self.title = title; self.fileName = title + ".mp4"; self.path = "/Pulse/" + title + ".mp4"
        self.size = 1_200_000_000; self.duration = duration; self.width = width; self.height = height
        self.date = year.map { "\($0)-01-01" }; self.year = year; self.poster = poster; self.thumb = poster
        self.studio = studio; self.performers = performers; self.matchStatus = matchStatus
        self.matchConfidence = 0.97; self.matchSource = .tpdb; self.favorite = favorite
        self.watchlist = false; self.progress = progress; self.addedAt = nil; self.source = .pcloud
    }

    /// "1080p", "4K"... derived from frame height.
    public var resolutionLabel: String? {
        guard let height else { return nil }
        switch height {
        case 2000...: return "4K"
        case 1400...: return "1440p"
        case 1000...: return "1080p"
        case 700...: return "720p"
        case 400...: return "480p"
        default: return "SD"
        }
    }

    public var isInProgress: Bool {
        guard let progress else { return false }
        return !progress.completed && progress.position > 5
    }
}
