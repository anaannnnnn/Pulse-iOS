#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Obsidian Mint: ink-black surfaces, hairline glass, one electric mint accent and a warm ember highlight.
public enum Theme {
    public static let bg = Color(hex: 0x050607)
    public static let surface = Color(hex: 0x0C0E10)
    public static let raised = Color(hex: 0x121518)
    public static let elevated = Color(hex: 0x1A1E22)
    public static let line = Color.white.opacity(0.08)
    public static let lineStrong = Color.white.opacity(0.17)

    public static let accent = Color(hex: 0x5CF2C3)
    public static let accentSoft = Color(hex: 0x9BF8DD)
    public static let accentDeep = Color(hex: 0x19B58C)
    /// Text and icons that sit on top of the accent.
    public static let onAccent = Color(hex: 0x03140E)
    /// Warm counterpoint for hearts, live states and highlights.
    public static let ember = Color(hex: 0xFF8A5C)
    public static let success = Color(hex: 0x4ADE80)
    public static let warning = Color(hex: 0xFBBF24)
    public static let danger = Color(hex: 0xFF6B6B)

    public static let text = Color(hex: 0xF2F5F4)
    public static let textSecondary = Color(hex: 0xA3ADAA)
    public static let textTertiary = Color(hex: 0x6C7673)

    public static let gradient = LinearGradient(colors: [accentSoft, accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    public static let emberGradient = LinearGradient(colors: [Color(hex: 0xFFB38A), ember, Color(hex: 0xE5603A)], startPoint: .topLeading, endPoint: .bottomTrailing)
    public static let scrim = LinearGradient(colors: [.clear, bg.opacity(0.4), bg.opacity(0.96)], startPoint: .top, endPoint: .bottom)
    /// Bright top-left to faint bottom-right rim used on glass cards.
    public static let rim = LinearGradient(colors: [.white.opacity(0.34), .white.opacity(0.06), .white.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)

    public enum Radius {
        public static let card: CGFloat = 24
        public static let control: CGFloat = 16
        public static let sheet: CGFloat = 32
    }

    public enum Space {
        public static let page: CGFloat = 20
        public static let rail: CGFloat = 14
        public static let tight: CGFloat = 8
    }

    /// Spring used for taps and toggles across the app.
    public static let tap: Animation = .spring(duration: 0.32, bounce: 0.35)
    /// Spring for larger layout moves (tab pill, sheets, cards).
    public static let glide: Animation = .spring(duration: 0.5, bounce: 0.22)
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// Stable teal-to-emerald colour for placeholder artwork.
    static func placeholder(seed: Int, shade: Double = 0) -> Color {
        let hue = 0.36 + Double(abs(seed) * 37 % 100) / 100 * 0.2
        return Color(hue: hue, saturation: 0.4, brightness: 0.2 + shade)
    }
}

public enum PulseFont {
    /// Wide, characterful headline face (Syne). Falls back to SF if the font did not load.
    public static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, weight: Font.Weight = .bold) -> Font {
        PulseFonts.register()
        let name: String = switch weight {
        case .heavy, .black: "Syne-ExtraBold"
        case .bold: "Syne-Bold"
        default: "Syne-SemiBold"
        }
        return .custom(name, size: size, relativeTo: style)
    }

    /// Editorial serif (DM Serif Display) for featured titles and category cards.
    public static func serif(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, italic: Bool = false) -> Font {
        PulseFonts.register()
        return .custom(italic ? "DMSerifDisplay-Italic" : "DMSerifDisplay-Regular", size: size, relativeTo: style)
    }

    public static func title(_ style: Font.TextStyle = .title2) -> Font {
        let size: CGFloat = switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 19
        case .headline: 16
        default: 15
        }
        return display(size, relativeTo: style, weight: .bold)
    }

    public static func label(_ style: Font.TextStyle = .subheadline) -> Font {
        .system(style, design: .default, weight: .semibold)
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
