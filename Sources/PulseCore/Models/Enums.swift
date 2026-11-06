import Foundation

public enum MatchStatus: String, LenientEnum, Hashable {
    case unmatched, queued, matched, manual, failed, ignored
    public static var fallback: MatchStatus { .unmatched }

    public var isResolved: Bool { self == .matched || self == .manual }
}

public enum SceneSource: String, LenientEnum, Hashable {
    case pcloud, torbox
    public static var fallback: SceneSource { .pcloud }
}

public enum MetadataProvider: String, LenientEnum, Hashable {
    case tpdb, stashdb
    public static var fallback: MetadataProvider { .tpdb }

    public var label: String { self == .tpdb ? "ThePornDB" : "StashDB" }
}

public enum SceneKind: String, LenientEnum, Hashable {
    case scene, movie, jav
    public static var fallback: SceneKind { .scene }
}

public enum LibrarySort: String, CaseIterable, Sendable, Hashable, Identifiable {
    case added, date, title, duration, size, random, lastWatched
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .added: "Recently added"
        case .date: "Release date"
        case .title: "Title"
        case .duration: "Duration"
        case .size: "File size"
        case .random: "Shuffle"
        case .lastWatched: "Last watched"
        }
    }
}

public enum WatchedFilter: String, CaseIterable, Sendable, Hashable, Identifiable {
    case any, `true`, `false`, inprogress
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .any: "All"
        case .true: "Watched"
        case .false: "Unwatched"
        case .inprogress: "In progress"
        }
    }
}

public enum TorboxKind: String, LenientEnum, Hashable {
    case torrents, usenet, webdl
    public static var fallback: TorboxKind { .torrents }
    public var label: String {
        switch self {
        case .torrents: "Torrents"
        case .usenet: "Usenet"
        case .webdl: "Web"
        }
    }
}

public enum QualityPreference: String, LenientEnum, Hashable, Identifiable {
    case original, p1080 = "1080p", p720 = "720p", p480 = "480p", auto
    public static var fallback: QualityPreference { .auto }
    public var id: String { rawValue }
    public var label: String { self == .auto ? "Auto" : (self == .original ? "Original" : rawValue) }
}
