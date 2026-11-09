#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import Observation

/// Accent palettes the user can pick in Settings → Appearance. Everything else in the theme is neutral graphite.
public enum AccentChoice: String, CaseIterable, Identifiable, Sendable {
    case netflix, jade, ice, rose, amber, violet

    public var id: String { rawValue }

    public var title: LocalizedStringKey {
        switch self {
        case .netflix: "Crimson"
        case .jade: "Jade"
        case .ice: "Ice"
        case .rose: "Rose"
        case .amber: "Tungsten"
        case .violet: "Violet"
        }
    }

    var base: UInt32 {
        switch self {
        case .netflix: 0xE50914
        case .jade: 0x5BC0A5
        case .ice: 0x7BA7F5
        case .rose: 0xE88AA3
        case .amber: 0xF2B24A
        case .violet: 0xA290F2
        }
    }

    var soft: UInt32 {
        switch self {
        case .netflix: 0xFF3B45
        case .jade: 0x92D6C3
        case .ice: 0xA9C6FA
        case .rose: 0xF1B0C1
        case .amber: 0xFFD27F
        case .violet: 0xC3B8F7
        }
    }

    var deep: UInt32 {
        switch self {
        case .netflix: 0xB20710
        case .jade: 0x2F8A76
        case .ice: 0x3F6FCC
        case .rose: 0xB8506C
        case .amber: 0xB87A12
        case .violet: 0x6E58C8
        }
    }

    public var swatch: Color { Color(hex: base) }
}

/// Holds the chosen accent. Views that read `Theme.accent` register with Observation, so they refresh on change.
@Observable
public final class AccentStore: @unchecked Sendable {
    public static let shared = AccentStore()
    private static let key = "pulse.accent.v3"

    public private(set) var choice: AccentChoice

    private init() {
        choice = UserDefaults.standard.string(forKey: Self.key).flatMap(AccentChoice.init(rawValue:)) ?? .amber
    }

    public func select(_ choice: AccentChoice) {
        self.choice = choice
        UserDefaults.standard.set(choice.rawValue, forKey: Self.key)
    }
}

/// Cinema Black: pure black, crimson accent, small-radius posters, glass only on system chrome.
public enum Theme {
    public static let bg = Color(hex: 0x000000)
    public static let surface = Color(hex: 0x141414)
    public static let raised = Color(hex: 0x1F1F1F)
    public static let elevated = Color(hex: 0x2A2A2A)
    public static let line = Color.white.opacity(0.07)
    public static let lineStrong = Color.white.opacity(0.14)

    public static var accent: Color { Color(hex: AccentStore.shared.choice.base) }
    public static var accentSoft: Color { Color(hex: AccentStore.shared.choice.soft) }
    public static var accentDeep: Color { Color(hex: AccentStore.shared.choice.deep) }
    /// Text and icons that sit on a solid accent fill (rare: progress knobs, badges).
    public static var onAccent: Color {
        switch AccentStore.shared.choice {
        case .netflix, .violet: .white
        default: Color(hex: 0x140E04)
        }
    }
    /// Soft coral for hearts and live states.
    public static let ember = Color(hex: 0xF08A7A)
    public static let success = Color(hex: 0x6FCF97)
    public static let warning = Color(hex: 0xE9B95F)
    public static let danger = Color(hex: 0xEF6F6F)

    public static let text = Color.white
    public static let textSecondary = Color(hex: 0xB3B3B3)
    public static let textTertiary = Color(hex: 0x808080)

    public static var gradient: LinearGradient {
        LinearGradient(colors: [accentSoft, accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    public static let scrim = LinearGradient(colors: [.clear, bg.opacity(0.45), bg.opacity(0.96)], startPoint: .top, endPoint: .bottom)
    /// Bright top-left to faint bottom-right rim for fallback glass.
    public static let rim = LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.05), .white.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)

    public enum Radius {
        /// Posters and thumbnails.
        public static let card: CGFloat = 10
        /// Buttons, fields, rows.
        public static let control: CGFloat = 14
        /// Grouped panels (slate, settings groups).
        public static let panel: CGFloat = 20
        public static let sheet: CGFloat = 28
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

/// Three bundled faces, all variable and all scaling with Dynamic Type:
/// Bodoni Moda (title-card display), Hanken Grotesk (interface), Martian Mono (timecodes and counters).
public enum PulseFont {
    static let displayFamily = "Bodoni Moda"
    static let displayItalic = "BodoniModa-Italic"
    static let uiFamily = "Hanken Grotesk"
    static let monoFace = "MartianMono-SemiExpandedRegular"

    /// Default point size of a text style at the standard Dynamic Type setting.
    static func base(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 15
        case .body: 17
        case .callout: 16
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    /// Title-card display face. `scale` enlarges it relative to the text style (hero titles use 1.5 and up).
    public static func display(_ style: Font.TextStyle = .largeTitle, scale: CGFloat = 1, weight: Font.Weight = .semibold, italic: Bool = true) -> Font {
        .custom(italic ? displayItalic : displayFamily, size: base(style) * scale, relativeTo: style).weight(weight)
    }

    /// Interface text in Hanken Grotesk.
    public static func ui(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .custom(uiFamily, size: base(style), relativeTo: style).weight(weight)
    }

    /// Timecodes, runtimes and counters in Martian Mono.
    public static func timecode(_ style: Font.TextStyle = .caption) -> Font {
        .custom(monoFace, size: base(style) * 0.92, relativeTo: style).weight(.medium)
    }

    // Older call sites.
    public static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, weight: Font.Weight = .bold) -> Font {
        .custom(displayItalic, size: size, relativeTo: style).weight(weight)
    }
    public static func serif(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, italic: Bool = false) -> Font {
        .custom(italic ? displayItalic : displayFamily, size: size, relativeTo: style)
    }
    public static func title(_ style: Font.TextStyle = .title2) -> Font { ui(style, weight: .bold) }
    public static func label(_ style: Font.TextStyle = .subheadline) -> Font { ui(style, weight: .semibold) }
    public static func headline(_ style: Font.TextStyle = .title2, weight: Font.Weight = .semibold) -> Font { display(style, weight: weight) }
}

extension EnvironmentValues {
    /// Server base URL used to resolve `/api/...` artwork paths.
    @Entry public var pulseImageBase: URL?
    @Entry public var pulseMediaToken: String?
    /// Blur poster art (privacy setting).
    @Entry public var pulseBlurArt: Bool = false
}
#endif
