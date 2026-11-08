#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import Observation

/// Accent palettes the user can pick in Settings → Appearance. Everything else in the theme is neutral graphite.
public enum AccentChoice: String, CaseIterable, Identifiable, Sendable {
    case jade, ice, rose, amber, violet

    public var id: String { rawValue }

    public var title: LocalizedStringKey {
        switch self {
        case .jade: "Jade"
        case .ice: "Ice"
        case .rose: "Rose"
        case .amber: "Amber"
        case .violet: "Violet"
        }
    }

    var base: UInt32 {
        switch self {
        case .jade: 0x5BC0A5
        case .ice: 0x7BA7F5
        case .rose: 0xE88AA3
        case .amber: 0xE3B260
        case .violet: 0xA290F2
        }
    }

    var soft: UInt32 {
        switch self {
        case .jade: 0x92D6C3
        case .ice: 0xA9C6FA
        case .rose: 0xF1B0C1
        case .amber: 0xEFCB8F
        case .violet: 0xC3B8F7
        }
    }

    var deep: UInt32 {
        switch self {
        case .jade: 0x2F8A76
        case .ice: 0x3F6FCC
        case .rose: 0xB8506C
        case .amber: 0xB5842F
        case .violet: 0x6E58C8
        }
    }

    public var swatch: Color { Color(hex: base) }
}

/// Holds the chosen accent. Views that read `Theme.accent` register with Observation, so they refresh on change.
@Observable
public final class AccentStore: @unchecked Sendable {
    public static let shared = AccentStore()
    private static let key = "pulse.accent"

    public private(set) var choice: AccentChoice

    private init() {
        choice = UserDefaults.standard.string(forKey: Self.key).flatMap(AccentChoice.init(rawValue:)) ?? .jade
    }

    public func select(_ choice: AccentChoice) {
        self.choice = choice
        UserDefaults.standard.set(choice.rawValue, forKey: Self.key)
    }
}

/// Graphite Glass: ink-black surfaces, real Liquid Glass on top, one quiet accent.
public enum Theme {
    public static let bg = Color(hex: 0x080910)
    public static let surface = Color(hex: 0x10121C)
    public static let raised = Color(hex: 0x191B27)
    public static let elevated = Color(hex: 0x242635)
    public static let line = Color.white.opacity(0.09)
    public static let lineStrong = Color.white.opacity(0.14)

    public static var accent: Color { Color(hex: AccentStore.shared.choice.base) }
    public static var accentSoft: Color { Color(hex: AccentStore.shared.choice.soft) }
    public static var accentDeep: Color { Color(hex: AccentStore.shared.choice.deep) }
    /// Text and icons that sit on a solid accent fill (rare: progress knobs, badges).
    public static let onAccent = Color(hex: 0x07080A)
    /// Soft coral for hearts and live states.
    public static let ember = Color(hex: 0xF08A7A)
    public static let success = Color(hex: 0x6FCF97)
    public static let warning = Color(hex: 0xE9B95F)
    public static let danger = Color(hex: 0xEF6F6F)

    public static let text = Color(hex: 0xF4F5F7)
    public static let textSecondary = Color(hex: 0xA1A7B0)
    public static let textTertiary = Color(hex: 0x9299A5)

    public static var gradient: LinearGradient {
        LinearGradient(colors: [accentSoft, accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static let scrim = LinearGradient(colors: [.clear, bg.opacity(0.45), bg.opacity(0.96)], startPoint: .top, endPoint: .bottom)
    /// Bright top-left to faint bottom-right rim for fallback glass.
    public static let rim = LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.05), .white.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)

    public enum Radius {
        public static let card: CGFloat = 24
        public static let control: CGFloat = 16
        public static let sheet: CGFloat = 32
    }

    /// 4-pt grid.
    public enum Space {
        public static let page: CGFloat = 20
        public static let rail: CGFloat = 12
        public static let tight: CGFloat = 8
        public static let section: CGFloat = 32
    }

    /// Spring for taps and toggles.
    public static let tap: Animation = .spring(duration: 0.3, bounce: 0.3)
    /// Spring for larger moves (sheets, cards, pills).
    public static let glide: Animation = .spring(duration: 0.5, bounce: 0.2)
    public static let entrance: Animation = .spring(duration: 0.7, bounce: 0.12)
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// Stable cool-slate colour for placeholder artwork.
    static func placeholder(seed: Int, shade: Double = 0) -> Color {
        let hue = 0.52 + Double(abs(seed) * 37 % 100) / 100 * 0.2
        return Color(hue: hue, saturation: 0.28, brightness: 0.2 + shade)
    }
}

/// System fonts only: SF Pro for UI and titles, New York for editorial moments.
public enum PulseFont {
    public static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, weight: Font.Weight = .bold) -> Font {
        .system(style, weight: weight)
    }

    public static func serif(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, italic: Bool = false) -> Font {
        let font = Font.system(style, weight: .regular, design: .serif)
        return italic ? font.italic() : font
    }

    public static func title(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, weight: .bold)
    }

    public static func label(_ style: Font.TextStyle = .subheadline) -> Font {
        .system(style, weight: .semibold)
    }
}

extension EnvironmentValues {
    /// Server base URL used to resolve `/api/...` artwork paths.
    @Entry public var pulseImageBase: URL?
    @Entry public var pulseMediaToken: String?
    /// Blur poster art (privacy setting).
    @Entry public var pulseBlurArt: Bool = false
}
#endif
