import Foundation

/// String enums that never fail decoding: unknown server values map to `fallback`.
public protocol LenientEnum: RawRepresentable, Codable, CaseIterable, Sendable where RawValue == String {
    static var fallback: Self { get }
}

public extension LenientEnum {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? Self.fallback
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
