import Foundation

public struct ParsedFilename: Codable, Hashable, Sendable {
    public let studio: String?
    public let date: String?
    public let title: String?
    public let performers: [String]
    public let resolution: String?
    public let `extension`: String?
}

public struct ExternalRef: Codable, Hashable, Sendable {
    public let id: String
    public let type: SceneKind?
    public let url: String?
}

public struct PcloudFileRef: Codable, Hashable, Sendable {
    public let fileId: Int
    public let folderId: Int
    public let contentType: String?
}

public struct SceneDetail: Codable, Hashable, Identifiable, Sendable {
    public var scene: Video
    public let description: String?
    public let tags: [Tag]
    public let performers: [Performer]
    public let tpdb: ExternalRef?
    public let stashdb: ExternalRef?
    public let parsed: ParsedFilename?
    public let pcloud: PcloudFileRef?
    public let trailer: String?
    public let backdrop: String?

    public var id: Int { scene.id }

    enum CodingKeys: String, CodingKey {
        case description, tags, performers, tpdb, stashdb, parsed, pcloud, trailer, backdrop
    }

    public init(from decoder: Decoder) throws {
        scene = try Video(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        tags = try c.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        performers = try c.decodeIfPresent([Performer].self, forKey: .performers) ?? []
        tpdb = try c.decodeIfPresent(ExternalRef.self, forKey: .tpdb)
        stashdb = try c.decodeIfPresent(ExternalRef.self, forKey: .stashdb)
        parsed = try c.decodeIfPresent(ParsedFilename.self, forKey: .parsed)
        pcloud = try c.decodeIfPresent(PcloudFileRef.self, forKey: .pcloud)
        trailer = try c.decodeIfPresent(String.self, forKey: .trailer)
        backdrop = try c.decodeIfPresent(String.self, forKey: .backdrop)
    }

    public func encode(to encoder: Encoder) throws {
        try scene.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(tags, forKey: .tags)
        try c.encode(performers, forKey: .performers)
    }

    public init(scene: Video, description: String? = nil, tags: [Tag] = [], performers: [Performer] = []) {
        self.scene = scene; self.description = description; self.tags = tags; self.performers = performers
        self.tpdb = nil; self.stashdb = nil; self.parsed = nil; self.pcloud = nil
        self.trailer = nil; self.backdrop = nil
    }
}

/// Body for `PATCH /api/scenes/:id`.
public struct SceneEdit: Codable, Hashable, Sendable {
    public var title: String?
    public var date: String?
    public var description: String?
    public var studioName: String?
    public var performerNames: [String]?
    public var tagNames: [String]?

    public init(title: String? = nil, date: String? = nil, description: String? = nil,
                studioName: String? = nil, performerNames: [String]? = nil, tagNames: [String]? = nil) {
        self.title = title; self.date = date; self.description = description
        self.studioName = studioName; self.performerNames = performerNames; self.tagNames = tagNames
    }
}
