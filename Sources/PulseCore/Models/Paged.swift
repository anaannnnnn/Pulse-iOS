import Foundation

public struct Paged<Item: Codable & Sendable>: Codable, Sendable {
    public let items: [Item]
    public let page: Int
    public let pageSize: Int
    public let total: Int
    public let totalPages: Int

    public init(items: [Item], page: Int = 1, pageSize: Int = 40, total: Int? = nil, totalPages: Int = 1) {
        self.items = items; self.page = page; self.pageSize = pageSize
        self.total = total ?? items.count; self.totalPages = totalPages
    }

    public var hasMore: Bool { page < totalPages }
}

public struct ItemList<Item: Codable & Sendable>: Codable, Sendable {
    public let items: [Item]
}
