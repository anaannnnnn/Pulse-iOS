#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Slow drifting violet aurora. Static when Reduce Motion is on or the device is in Low Power Mode.
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
                        (tint, 0.0, 0.18, 0.80), (Theme.accentDeep, 2.1, 0.12, 0.95), (Color(hex: 0xC026D3), 4.2, 0.07, 0.70),
                    ]
                    for (color, phase, speed, scale) in blobs {
                        let x = size.width * (0.5 + 0.38 * sin(t * speed + phase))
                        let y = size.height * (0.28 + 0.22 * cos(t * speed * 0.8 + phase))
                        let radius = max(size.width, size.height) * scale * 0.55
                        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        gc.fill(Path(ellipseIn: rect),
                                with: .radialGradient(Gradient(colors: [color.opacity(0.34 * intensity), .clear]),
                                                      center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius))
                    }
                }
            }
            LinearGradient(colors: [.clear, Theme.bg.opacity(0.85)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

public extension View {
    func pulseScreenBackground(tint: Color = Theme.accent, intensity: Double = 0.8) -> some View {
        background { AuroraBackground(tint: tint, intensity: intensity) }
    }
}
#endif
