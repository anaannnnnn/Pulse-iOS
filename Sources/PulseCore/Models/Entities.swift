import Foundation

public struct PerformerRef: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let image: String?
}

public struct StudioRef: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
}

public struct Performer: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String?
    public let image: String?
    public let thumb: String?
    public let gender: String?
    public let tpdbId: String?
    public let stashId: String?
    public let source: MetadataProvider?
    public let sceneCount: Int
    public var favorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, slug, image, thumb, gender, tpdbId, stashId, source, sceneCount, favorite
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        thumb = try c.decodeIfPresent(String.self, forKey: .thumb)
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        tpdbId = try c.decodeIfPresent(String.self, forKey: .tpdbId)
        stashId = try c.decodeIfPresent(String.self, forKey: .stashId)
        source = try c.decodeIfPresent(MetadataProvider.self, forKey: .source)
        sceneCount = try c.decodeIfPresent(Int.self, forKey: .sceneCount) ?? 0
        favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
    }

    public init(id: Int, name: String, image: String? = nil, gender: String? = nil,
                sceneCount: Int = 0, favorite: Bool = false) {
        self.id = id; self.name = name; self.slug = nil; self.image = image; self.thumb = image
        self.gender = gender; self.tpdbId = nil; self.stashId = nil; self.source = nil
        self.sceneCount = sceneCount; self.favorite = favorite
    }

    public var portrait: String? { thumb ?? image }
}

public struct PerformerDetail: Codable, Hashable, Identifiable, Sendable {
    public let performer: Performer
    public let bio: String?
    public let aliases: [String]
    public let birthday: String?
    public let birthplace: String?
    public let ethnicity: String?
    public let nationality: String?
    public let hairColor: String?
    public let eyeColor: String?
    public let height: String?
    public let weight: String?
    public let measurements: String?
    public let cupSize: String?
    public let tattoos: String?
    public let piercings: String?
    public let careerStart: String?
    public let careerEnd: String?
    public let images: [String]
    public let links: [String: String]
    public var scenes: [Video]

    public var id: Int { performer.id }

    enum CodingKeys: String, CodingKey {
        case bio, aliases, birthday, birthplace, ethnicity, nationality, hairColor, eyeColor
        case height, weight, measurements, cupSize, tattoos, piercings, careerStart, careerEnd
        case images, links, scenes
    }

    public init(from decoder: Decoder) throws {
        performer = try Performer(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        aliases = try c.decodeIfPresent([String].self, forKey: .aliases) ?? []
        birthday = try c.decodeIfPresent(String.self, forKey: .birthday)
        birthplace = try c.decodeIfPresent(String.self, forKey: .birthplace)
        ethnicity = try c.decodeIfPresent(String.self, forKey: .ethnicity)
        nationality = try c.decodeIfPresent(String.self, forKey: .nationality)
        hairColor = try c.decodeIfPresent(String.self, forKey: .hairColor)
        eyeColor = try c.decodeIfPresent(String.self, forKey: .eyeColor)
        height = try c.decodeIfPresent(String.self, forKey: .height)
        weight = try c.decodeIfPresent(String.self, forKey: .weight)
        measurements = try c.decodeIfPresent(String.self, forKey: .measurements)
        cupSize = try c.decodeIfPresent(String.self, forKey: .cupSize)
        tattoos = try c.decodeIfPresent(String.self, forKey: .tattoos)
        piercings = try c.decodeIfPresent(String.self, forKey: .piercings)
        careerStart = try c.decodeIfPresent(String.self, forKey: .careerStart)
        careerEnd = try c.decodeIfPresent(String.self, forKey: .careerEnd)
        images = try c.decodeIfPresent([String].self, forKey: .images) ?? []
        links = try c.decodeIfPresent([String: String].self, forKey: .links) ?? [:]
        scenes = try c.decodeIfPresent([Video].self, forKey: .scenes) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        try performer.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(bio, forKey: .bio)
        try c.encode(aliases, forKey: .aliases)
        try c.encode(images, forKey: .images)
        try c.encode(links, forKey: .links)
        try c.encode(scenes, forKey: .scenes)
    }

    /// Label/value pairs that are present, in display order.
    public var facts: [(label: String, value: String)] {
        let pairs: [(String, String?)] = [
            ("Born", birthday), ("Birthplace", birthplace), ("Nationality", nationality),
            ("Ethnicity", ethnicity), ("Hair", hairColor), ("Eyes", eyeColor),
            ("Height", height), ("Weight", weight), ("Measurements", measurements),
            ("Cup", cupSize), ("Tattoos", tattoos), ("Piercings", piercings),
            ("Career start", careerStart), ("Career end", careerEnd),
        ]
        return pairs.compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return (label, value)
        }
    }
}

public struct Studio: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String?
    public let logo: String?
    public let parent: String?
    public let source: MetadataProvider?
    public let sceneCount: Int
    public var favorite: Bool

    enum CodingKeys: String, CodingKey { case id, name, slug, logo, parent, source, sceneCount, favorite }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        logo = try c.decodeIfPresent(String.self, forKey: .logo)
        parent = try c.decodeIfPresent(String.self, forKey: .parent)
        source = try c.decodeIfPresent(MetadataProvider.self, forKey: .source)
        sceneCount = try c.decodeIfPresent(Int.self, forKey: .sceneCount) ?? 0
        favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
    }

    public init(id: Int, name: String, sceneCount: Int = 0, favorite: Bool = false) {
        self.id = id; self.name = name; self.slug = nil; self.logo = nil; self.parent = nil
        self.source = nil; self.sceneCount = sceneCount; self.favorite = favorite
    }
}

public struct StudioDetail: Codable, Hashable, Identifiable, Sendable {
    public let studio: Studio
    public var scenes: [Video]
    public var id: Int { studio.id }

    enum CodingKeys: String, CodingKey { case scenes }

    public init(from decoder: Decoder) throws {
        studio = try Studio(from: decoder)
        scenes = try decoder.container(keyedBy: CodingKeys.self).decodeIfPresent([Video].self, forKey: .scenes) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        try studio.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(scenes, forKey: .scenes)
    }
}

public struct Tag: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String?
    public let source: MetadataProvider?
    public let sceneCount: Int

    public init(id: Int, name: String, sceneCount: Int = 0) {
        self.id = id; self.name = name; self.slug = nil; self.source = nil; self.sceneCount = sceneCount
    }

    enum CodingKeys: String, CodingKey { case id, name, slug, source, sceneCount }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        source = try c.decodeIfPresent(MetadataProvider.self, forKey: .source)
        sceneCount = try c.decodeIfPresent(Int.self, forKey: .sceneCount) ?? 0
    }
}

extension PerformerDetail {
    /// Copy with a different scene list (sample data, pagination merges).
    public func withScenes(_ scenes: [Video]) -> PerformerDetail {
        var copy = self
        copy.scenes = scenes
        return copy
    }
}

extension StudioDetail {
    public func withScenes(_ scenes: [Video]) -> StudioDetail {
        var copy = self
        copy.scenes = scenes
        return copy
    }
}
