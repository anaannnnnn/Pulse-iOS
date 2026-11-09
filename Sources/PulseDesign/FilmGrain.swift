#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Static film grain: drawn once from a fixed seed, blended with overlay. Adds the tooth a flat gradient lacks, at no per-frame cost.
public struct FilmGrain: View {
    var opacity: Double

    public init(opacity: Double = 0.16) { self.opacity = opacity }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var state: UInt64 = 0x9E3779B97F4A7C15
            func next() -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
            }
            let count = Int(size.width * size.height / 28)
            for _ in 0..<count {
                let x = next() * size.width, y = next() * size.height
                let light = next() > 0.5
                context.fill(Path(CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(light ? .white : .black))
            }
        }
        .blendMode(.overlay)
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
