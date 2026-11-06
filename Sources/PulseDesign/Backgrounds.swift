#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Ink-black stage with a slowly drifting mesh gradient in the accent colour. Static under Reduce Motion or Low Power Mode.
public struct AuroraBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var tint: Color?
    var intensity: Double

    public init(tint: Color? = nil, intensity: Double = 1) {
        self.tint = tint
        self.intensity = intensity
    }

    private var isStatic: Bool { reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled }

    public var body: some View {
        let color = tint ?? Theme.accentDeep
        ZStack {
            Theme.bg
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: isStatic)) { context in
                let t = isStatic ? 0 : Float(context.date.timeIntervalSinceReferenceDate)
                let a = Float(0.12 * sin(Double(t) * 0.23)), b = Float(0.12 * cos(Double(t) * 0.19))
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5 + a, 0], [1, 0],
                    [0, 0.45 + b], [0.5 - b, 0.5 + a], [1, 0.55 - a],
                    [0, 1], [0.5 + b, 1], [1, 1],
                ], colors: [
                    color.opacity(0.34 * intensity), Theme.bg.opacity(0), color.opacity(0.18 * intensity),
                    Theme.bg.opacity(0), color.opacity(0.14 * intensity), Theme.bg.opacity(0),
                    Theme.bg.opacity(0), color.opacity(0.10 * intensity), Theme.bg.opacity(0),
                ])
            }
            LinearGradient(colors: [.clear, Theme.bg.opacity(0.85)], startPoint: .center, endPoint: .bottom)
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
