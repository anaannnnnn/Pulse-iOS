#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Violet Glass: aubergine black, frosted surfaces, one violet accent.
public enum Theme {
    public static let bg = Color(hex: 0x0C0913)
    public static let surface = Color(hex: 0x15111F)
    public static let raised = Color(hex: 0x1D172B)
    public static let elevated = Color(hex: 0x261F38)
    public static let line = Color.white.opacity(0.09)
    public static let lineStrong = Color.white.opacity(0.18)

    public static let accent = Color(hex: 0x8B5CF6)
    public static let accentSoft = Color(hex: 0xA78BFA)
    public static let accentDeep = Color(hex: 0x6D28D9)
    public static let success = Color(hex: 0x34D399)
    public static let warning = Color(hex: 0xFBBF24)
    public static let danger = Color(hex: 0xF87171)

    public static let text = Color(hex: 0xF1ECFB)
    public static let textSecondary = Color(hex: 0xB9B0D1)
    public static let textTertiary = Color(hex: 0x8F86AA)

    public static let gradient = LinearGradient(colors: [accentSoft, accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    public static let scrim = LinearGradient(colors: [.clear, bg.opacity(0.35), bg.opacity(0.92)], startPoint: .top, endPoint: .bottom)

    public enum Radius {
        public static let card: CGFloat = 20
        public static let control: CGFloat = 14
        public static let sheet: CGFloat = 28
    }

    public enum Space {
        public static let page: CGFloat = 20
        public static let rail: CGFloat = 14
        public static let tight: CGFloat = 8
    }
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// Stable violet-leaning colour for placeholder artwork.
    static func placeholder(seed: Int, shade: Double = 0) -> Color {
        let hue = 0.70 + Double(abs(seed) * 37 % 100) / 100 * 0.16
        return Color(hue: hue, saturation: 0.55, brightness: 0.34 + shade)
    }
}

public enum PulseFont {
    /// Wide display face for titles and numerals. Uses "Unbounded" when the app bundles it, otherwise SF Rounded.
    public static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title, weight: Font.Weight = .bold) -> Font {
        .custom("Unbounded", size: size, relativeTo: style).weight(weight)
    }

    public static func title(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, design: .rounded, weight: .bold)
    }

    public static func label(_ style: Font.TextStyle = .subheadline) -> Font {
        .system(style, design: .rounded, weight: .medium)
    }
}

extension EnvironmentValues {
    /// Server base URL used to resolve `/api/...` artwork paths.
    @Entry public var pulseImageBase: URL?
    /// Blur poster art (privacy setting).
    @Entry public var pulseBlurArt: Bool = false
}
#endif
