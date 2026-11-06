import Foundation

public enum RailItem: Codable, Hashable, Sendable, Identifiable {
    case scene(Video)
    case performer(Performer)

    public var id: String {
        switch self {
        case .scene(let s): "s\(s.id)"
        case .performer(let p): "p\(p.id)"
        }
    }

    public init(from decoder: Decoder) throws {
        // Scenes carry `fileName`; performers do not.
        let keys = try decoder.container(keyedBy: DynamicKey.self)
        if keys.contains(DynamicKey("fileName")) {
            self = .scene(try Video(from: decoder))
        } else {
            self = .performer(try Performer(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .scene(let s): try s.encode(to: encoder)
        case .performer(let p): try p.encode(to: encoder)
        }
    }
}

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

public struct HomeRail: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, LenientEnum, Hashable {
        case scenes, performers
        public static var fallback: Kind { .scenes }
    }

    public let id: String
    public let title: String
    public let kind: Kind
    public let items: [RailItem]

    public var scenes: [Video] {
        items.compactMap { if case .scene(let s) = $0 { s } else { nil } }
    }

    public var performers: [Performer] {
        items.compactMap { if case .performer(let p) = $0 { p } else { nil } }
    }

    public init(id: String, title: String, kind: Kind, items: [RailItem]) {
        self.id = id; self.title = title; self.kind = kind; self.items = items
    }
}

public struct HomeFeed: Codable, Hashable, Sendable {
    public let hero: [Video]
    public let rails: [HomeRail]

    public init(hero: [Video], rails: [HomeRail]) { self.hero = hero; self.rails = rails }
}

public struct YearFacet: Codable, Hashable, Sendable, Identifiable {
    public let year: Int
    public let count: Int
    public var id: Int { year }
}

public struct LibraryTotals: Codable, Hashable, Sendable {
    public let scenes: Int
    public let matched: Int
    public let unmatched: Int
    public let favorites: Int
}

public struct LibraryFacets: Codable, Hashable, Sendable {
    public let years: [YearFacet]
    public let studios: [Studio]
    public let tags: [Tag]
    public let performers: [Performer]
    public let durationMax: Double
    public let totals: LibraryTotals
}

public struct FavoritesBundle: Codable, Hashable, Sendable {
    public let scenes: [Video]
    public let performers: [Performer]
    public let studios: [Studio]
}
