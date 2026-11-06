import Foundation

public struct ScanStatus: Codable, Hashable, Sendable {
    public enum State: String, LenientEnum, Hashable {
        case idle, running, error
        public static var fallback: State { .idle }
    }
    public let state: State
    public let startedAt: String?
    public let finishedAt: String?
    public let foldersScanned: Int
    public let filesSeen: Int
    public let videosFound: Int
    public let added: Int
    public let removed: Int
    public let updated: Int
    public let currentPath: String?
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case state, startedAt, finishedAt, foldersScanned, filesSeen, videosFound, added, removed, updated, currentPath, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(State.self, forKey: .state) ?? .idle
        startedAt = try c.decodeIfPresent(String.self, forKey: .startedAt)
        finishedAt = try c.decodeIfPresent(String.self, forKey: .finishedAt)
        foldersScanned = try c.decodeIfPresent(Int.self, forKey: .foldersScanned) ?? 0
        filesSeen = try c.decodeIfPresent(Int.self, forKey: .filesSeen) ?? 0
        videosFound = try c.decodeIfPresent(Int.self, forKey: .videosFound) ?? 0
        added = try c.decodeIfPresent(Int.self, forKey: .added) ?? 0
        removed = try c.decodeIfPresent(Int.self, forKey: .removed) ?? 0
        updated = try c.decodeIfPresent(Int.self, forKey: .updated) ?? 0
        currentPath = try c.decodeIfPresent(String.self, forKey: .currentPath)
        error = try c.decodeIfPresent(String.self, forKey: .error)
    }

    public static let idle = ScanStatus(state: .idle)

    public init(state: State) {
        self.state = state; startedAt = nil; finishedAt = nil; foldersScanned = 0; filesSeen = 0
        videosFound = 0; added = 0; removed = 0; updated = 0; currentPath = nil; error = nil
    }
}

public struct PcloudStatus: Codable, Hashable, Sendable {
    public let connected: Bool
    public let email: String?
    public let region: String?
    public let apiHost: String?
    public let quota: Double?
    public let usedQuota: Double?
    public let connectedAt: String?
    public let redirectUri: String?
    public let clientConfigured: Bool?

    public init(connected: Bool, email: String? = nil, quota: Double? = nil, usedQuota: Double? = nil) {
        self.connected = connected; self.email = email; self.region = "eu"; self.apiHost = nil
        self.quota = quota; self.usedQuota = usedQuota; self.connectedAt = nil
        self.redirectUri = nil; self.clientConfigured = true
    }

    public var usedFraction: Double {
        guard let quota, let usedQuota, quota > 0 else { return 0 }
        return min(max(usedQuota / quota, 0), 1)
    }
}

public struct PcloudAuthorizeURL: Codable, Hashable, Sendable {
    public let url: String
    public let redirectUri: String?
    public let state: String?
}

public struct PcloudFolder: Codable, Hashable, Sendable, Identifiable {
    public let folderId: Int
    public let name: String
    public let path: String
    public let selected: Bool?
    public var id: Int { folderId }
}

public struct PcloudFolderListing: Codable, Hashable, Sendable {
    public let folderId: Int
    public let name: String
    public let path: String
    public let parentId: Int?
    public let folders: [PcloudFolder]
    public let videoCount: Int
}

public struct ScanFolder: Codable, Hashable, Sendable, Identifiable {
    public let folderId: Int
    public let path: String?
    public let name: String?
    public var id: Int { folderId }
    public init(folderId: Int, path: String? = nil, name: String? = nil) {
        self.folderId = folderId; self.path = path; self.name = name
    }
}

public struct ScanFolders: Codable, Hashable, Sendable {
    public let folders: [ScanFolder]
}

public struct TorboxStatus: Codable, Hashable, Sendable {
    public let linked: Bool
    public let source: String?
    public let email: String?
    public let plan: Int?
    public let planName: String?
    public let premiumExpiresAt: String?
    public let error: String?
}

public struct TorboxFile: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let shortName: String?
    public let size: Int64
    public let mime: String?
    public let isVideo: Bool
}

public struct TorboxItem: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let type: TorboxKind
    public let name: String
    public let hash: String?
    public let size: Int64
    public let progress: Double
    public let state: String
    public let downloadSpeed: Double
    public let uploadSpeed: Double
    public let seeds: Int?
    public let peers: Int?
    public let eta: Double?
    public let ready: Bool
    public let createdAt: String?
    public let files: [TorboxFile]

    enum CodingKeys: String, CodingKey {
        case id, type, name, hash, size, progress, state, downloadSpeed, uploadSpeed, seeds, peers, eta, ready, createdAt, files
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        type = try c.decodeIfPresent(TorboxKind.self, forKey: .type) ?? .torrents
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Untitled"
        hash = try c.decodeIfPresent(String.self, forKey: .hash)
        size = try c.decodeIfPresent(Int64.self, forKey: .size) ?? 0
        progress = try c.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? ""
        downloadSpeed = try c.decodeIfPresent(Double.self, forKey: .downloadSpeed) ?? 0
        uploadSpeed = try c.decodeIfPresent(Double.self, forKey: .uploadSpeed) ?? 0
        seeds = try c.decodeIfPresent(Int.self, forKey: .seeds)
        peers = try c.decodeIfPresent(Int.self, forKey: .peers)
        eta = try c.decodeIfPresent(Double.self, forKey: .eta)
        ready = try c.decodeIfPresent(Bool.self, forKey: .ready) ?? false
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        files = try c.decodeIfPresent([TorboxFile].self, forKey: .files) ?? []
    }
}

public struct TorboxAddResult: Codable, Hashable, Sendable {
    public let type: TorboxKind?
    public let id: Int?
    public let hash: String?
    public let message: String?
}

public struct TorboxStream: Codable, Hashable, Sendable {
    public let url: String
    public let mime: String?
    public let name: String?
}

public struct TorboxImportResult: Codable, Hashable, Sendable {
    public let added: Int
    public let seen: Int
}
