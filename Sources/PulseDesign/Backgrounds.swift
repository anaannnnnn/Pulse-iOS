#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Ink-black stage with two slow mint glows and a faint dot grid. Static when Reduce Motion is on or in Low Power Mode.
public struct AuroraBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var tint: Color
    var intensity: Double

    public init(tint: Color = Theme.accent, intensity: Double = 1) {
        self.tint = tint
        self.intensity = intensity
    }

    private var isStatic: Bool { reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled }

    public var body: some View {
        ZStack {
            Theme.bg
            TimelineView(.animation(minimumInterval: 1.0 / 24, paused: isStatic)) { context in
                let t = isStatic ? 0 : context.date.timeIntervalSinceReferenceDate
                Canvas { gc, size in
                    let blobs: [(Color, Double, Double, Double)] = [
                        (tint, 0.0, 0.16, 0.85), (Theme.accentDeep, 2.4, 0.11, 1.0), (Color(hex: 0x0E7C86), 4.4, 0.07, 0.8),
                    ]
                    for (color, phase, speed, scale) in blobs {
                        let x = size.width * (0.5 + 0.4 * sin(t * speed + phase))
                        let y = size.height * (0.22 + 0.2 * cos(t * speed * 0.8 + phase))
                        let radius = max(size.width, size.height) * scale * 0.5
                        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        gc.fill(Path(ellipseIn: rect),
                                with: .radialGradient(Gradient(colors: [color.opacity(0.22 * intensity), .clear]),
                                                      center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius))
                    }
                }
            }
            DotGrid().opacity(0.5)
            LinearGradient(colors: [.clear, Theme.bg.opacity(0.9)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Tiny dots on a 22pt grid that fade out toward the bottom.
struct DotGrid: View {
    var body: some View {
        Canvas { gc, size in
            let step: CGFloat = 22
            for row in 0..<Int(size.height / step) {
                for col in 0..<Int(size.width / step) {
                    let rect = CGRect(x: CGFloat(col) * step + 10, y: CGFloat(row) * step + 10, width: 1.4, height: 1.4)
                    gc.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.07)))
                }
            }
        }
        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
        .allowsHitTesting(false)
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
    func pulseScreenBackground(tint: Color = Theme.accent, intensity: Double = 0.8) -> some View {
        background { AuroraBackground(tint: tint, intensity: intensity) }
    }

    /// Screen background that takes its colour from artwork (hero, detail, search).
    func pulseAmbientBackground(path: String?, seed: Int, strength: Double = 0.55) -> some View {
        background { AmbientBackdrop(path: path, seed: seed, strength: strength) }
    }
}
#endif
