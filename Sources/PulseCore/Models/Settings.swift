import Foundation

public struct PlaybackSettings: Codable, Hashable, Sendable {
    public var autoplayNext: Bool = true
    public var defaultQuality: QualityPreference = .auto
    public var preferHls: Bool = false
    public var resumePlayback: Bool = true
    public var skipSeconds: Int = 10
    public var playbackRate: Double = 1
    public var subtitlesEnabled: Bool = false
    public var subtitleLang: String?
    public var muted: Bool = false

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        autoplayNext = try c.decodeIfPresent(Bool.self, forKey: .autoplayNext) ?? true
        defaultQuality = try c.decodeIfPresent(QualityPreference.self, forKey: .defaultQuality) ?? .auto
        preferHls = try c.decodeIfPresent(Bool.self, forKey: .preferHls) ?? false
        resumePlayback = try c.decodeIfPresent(Bool.self, forKey: .resumePlayback) ?? true
        skipSeconds = try c.decodeIfPresent(Int.self, forKey: .skipSeconds) ?? 10
        playbackRate = try c.decodeIfPresent(Double.self, forKey: .playbackRate) ?? 1
        subtitlesEnabled = try c.decodeIfPresent(Bool.self, forKey: .subtitlesEnabled) ?? false
        subtitleLang = try c.decodeIfPresent(String.self, forKey: .subtitleLang)
        muted = try c.decodeIfPresent(Bool.self, forKey: .muted) ?? false
    }
}

public struct LibrarySettings: Codable, Hashable, Sendable {
    public var autoMatch: Bool = true
    public var matchThreshold: Double = 0.85
    public var scanIntervalHours: Int = 0
    public var hashMatch: Bool = true

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        autoMatch = try c.decodeIfPresent(Bool.self, forKey: .autoMatch) ?? true
        matchThreshold = try c.decodeIfPresent(Double.self, forKey: .matchThreshold) ?? 0.85
        scanIntervalHours = try c.decodeIfPresent(Int.self, forKey: .scanIntervalHours) ?? 0
        hashMatch = try c.decodeIfPresent(Bool.self, forKey: .hashMatch) ?? true
    }
}

public struct MetadataSettings: Codable, Hashable, Sendable {
    public var tpdb: Bool = true
    public var stashdb: Bool = true

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tpdb = try c.decodeIfPresent(Bool.self, forKey: .tpdb) ?? true
        stashdb = try c.decodeIfPresent(Bool.self, forKey: .stashdb) ?? true
    }
}

public struct ServerSettings: Codable, Hashable, Sendable {
    public var autoLockMinutes: Int = 0
    public var blurThumbnails: Bool = false
    public var hideFromRecents: Bool = false
    public var playback = PlaybackSettings()
    public var library = LibrarySettings()
    public var metadata = MetadataSettings()

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        autoLockMinutes = try c.decodeIfPresent(Int.self, forKey: .autoLockMinutes) ?? 0
        blurThumbnails = try c.decodeIfPresent(Bool.self, forKey: .blurThumbnails) ?? false
        hideFromRecents = try c.decodeIfPresent(Bool.self, forKey: .hideFromRecents) ?? false
        playback = try c.decodeIfPresent(PlaybackSettings.self, forKey: .playback) ?? PlaybackSettings()
        library = try c.decodeIfPresent(LibrarySettings.self, forKey: .library) ?? LibrarySettings()
        metadata = try c.decodeIfPresent(MetadataSettings.self, forKey: .metadata) ?? MetadataSettings()
    }
}

public enum ClearDataScope: String, CaseIterable, Sendable, Identifiable {
    case progress, cache, favorites, metadata, library, all
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .progress: "Watch history"
        case .cache: "Cache"
        case .favorites: "Favourites"
        case .metadata: "Matched metadata"
        case .library: "Library index"
        case .all: "Everything"
        }
    }
}

public struct SessionState: Codable, Hashable, Sendable {
    public struct Cloud: Codable, Hashable, Sendable {
        public let connected: Bool
        public let email: String?
    }
    public struct Linked: Codable, Hashable, Sendable { public let linked: Bool }
    public struct Configured: Codable, Hashable, Sendable { public let configured: Bool }

    public let locked: Bool
    public let pinEnabled: Bool
    public let pcloud: Cloud?
    public let torbox: Linked?
    public let tpdb: Configured?
    public let stashdb: Configured?
    public let scan: ScanStatus?

    public init(locked: Bool) {
        self.locked = locked; pinEnabled = true; pcloud = nil; torbox = nil; tpdb = nil; stashdb = nil; scan = nil
    }
}

public struct HealthInfo: Codable, Hashable, Sendable {
    public let ok: Bool
    public let version: String?
    public let time: String?
}
