#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Pure-black house with a faint cone of projector light falling from the top edge. Static: costs nothing per frame.
public struct AuroraBackground: View {
    var tint: Color?
    var intensity: Double

    public init(tint: Color? = nil, intensity: Double = 1) {
        self.tint = tint
        self.intensity = intensity
    }

    public var body: some View {
        let color = tint ?? Theme.accentDeep
        ZStack {
            Theme.bg
            RadialGradient(colors: [color.opacity(0.26 * intensity), color.opacity(0.06 * intensity), .clear],
                           center: UnitPoint(x: 0.5, y: -0.05), startRadius: 0, endRadius: 520)
            LinearGradient(colors: [.clear, Theme.bg.opacity(0.9)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Blurred, over-scaled artwork that bleeds colour into the screen behind it. Cross-fades when the artwork changes.
public struct AmbientBackdrop: View {
    let path: String?
    let seed: Int
    var strength: Double

    public init(path: String?, seed: Int, strength: Double = 0.55) {
        self.path = path
        self.seed = seed
        self.strength = strength
    }

    public var body: some View {
        ZStack {
            Theme.bg
            PulseArt(path, seed: seed)
                .id(path ?? "\(seed)")
                .saturation(1.35)
                .blur(radius: 70)
                .scaleEffect(1.5)
                .opacity(strength)
                .transition(.opacity)
            LinearGradient(colors: [Theme.bg.opacity(0.1), Theme.bg.opacity(0.7), Theme.bg], startPoint: .top, endPoint: .bottom)
        }
        .animation(.smooth(duration: 0.8), value: path)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

public extension View {
    func pulseScreenBackground(tint: Color? = nil, intensity: Double = 0.8) -> some View {
        background { AuroraBackground(tint: tint, intensity: intensity) }
    }

    /// Screen background that takes its colour from artwork (hero, detail, search).
    func pulseAmbientBackground(path: String?, seed: Int, strength: Double = 0.55) -> some View {
        background { AmbientBackdrop(path: path, seed: seed, strength: strength) }
    }
}
#endif
