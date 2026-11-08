#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Cinematic artwork drawn in code. It stands in wherever there is no picture yet (loading, demo, missing thumbnail):
/// a seeded palette, a drifting colour mesh, a light bloom, an anamorphic streak, a vignette and film grain.
public struct PosterArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let seed: Int
    var animated: Bool
    var lite: Bool

    /// `lite` skips the mesh and grain: gradients only, for walls with dozens of tiles.
    public init(seed: Int, animated: Bool = false, lite: Bool = false) {
        self.seed = seed
        self.animated = animated
        self.lite = lite
    }

    private struct Palette {
        let shadow: UInt32, deep: UInt32, mid: UInt32, light: UInt32
    }

    private static let palettes: [Palette] = [
        Palette(shadow: 0x081A1F, deep: 0x0F4C52, mid: 0x2E9E8F, light: 0xF0A06A),
        Palette(shadow: 0x120B24, deep: 0x3A2578, mid: 0x8A52B8, light: 0xF07C9E),
        Palette(shadow: 0x1A0F08, deep: 0x6B3A12, mid: 0xC77A26, light: 0xF6D58A),
        Palette(shadow: 0x070F1C, deep: 0x1D4A7A, mid: 0x4D95CC, light: 0xBFE3F7),
        Palette(shadow: 0x190810, deep: 0x6E1A2F, mid: 0xC23A52, light: 0xF6A38F),
        Palette(shadow: 0x06130F, deep: 0x14573F, mid: 0x3FA77B, light: 0xD6EDA8),
    ]

    private func unit(_ n: Int) -> Double {
        let x = sin(Double(seed &* 7919 &+ n &* 104_729) * 12.9898) * 43758.5453
        return x - x.rounded(.down)
    }

    private func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    public var body: some View {
        let p = Self.palettes[abs(seed) % Self.palettes.count]
        let still = reduceMotion || !animated
        if lite { liteBody(p) } else { fullBody(p, still: still) }
    }

    private func liteBody(_ p: Palette) -> some View {
        ZStack {
            LinearGradient(colors: [color(p.shadow), color(p.deep), color(p.mid)],
                           startPoint: unit(2) > 0.5 ? .topLeading : .topTrailing, endPoint: .bottom)
            bloom(p)
            RadialGradient(colors: [.clear, .black.opacity(0.6)], center: .center, startRadius: 20, endRadius: 200)
        }
        .saturation(0.82)
        .accessibilityHidden(true)
    }

    private func fullBody(_ p: Palette, still: Bool) -> some View {
        ZStack {
            if still {
                mesh(p, t: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
                    mesh(p, t: context.date.timeIntervalSinceReferenceDate)
                }
            }
            bloom(p)
            streak
            RadialGradient(colors: [.clear, .black.opacity(0.7)], center: .center, startRadius: 30, endRadius: 460)
            Grain(seed: seed).blendMode(.overlay).opacity(0.5)
        }
        .saturation(0.82)
        .clipped()
        .accessibilityHidden(true)
    }

    private func mesh(_ p: Palette, t: Double) -> some View {
        let flip = unit(2) > 0.5
        let row1 = [color(p.shadow), color(p.deep), color(p.mid)]
        let row2 = [color(p.deep), color(p.mid), color(p.light)]
        let row3 = [color(p.shadow), color(p.shadow), color(p.deep)]
        let rows = [row1, row2, row3].map { flip ? Array($0.reversed()) : $0 }
        let a1 = Float(0.14 * (unit(6) - 0.5) + 0.06 * sin(t * 0.31 + Double(seed)))
        let b1 = Float(0.14 * (unit(7) - 0.5) + 0.06 * cos(t * 0.27 + Double(seed)))
        let a2 = Float(0.20 * (unit(8) - 0.5) + 0.08 * sin(t * 0.22))
        let b2 = Float(0.20 * (unit(9) - 0.5) + 0.08 * cos(t * 0.25))
        let a3 = Float(0.10 * (unit(10) - 0.5) + 0.05 * sin(t * 0.35 + 2))
        return MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5 + a1, 0], [1, 0],
            [0, 0.5 + b1], [0.5 + a2, 0.5 + b2], [1, 0.5 - b1],
            [0, 1], [0.5 + a3, 1], [1, 1],
        ], colors: rows.flatMap { $0 })
    }

    private func bloom(_ p: Palette) -> some View {
        RadialGradient(colors: [color(p.light).opacity(0.34), color(p.light).opacity(0)],
                       center: UnitPoint(x: 0.15 + unit(3) * 0.7, y: 0.1 + unit(4) * 0.5),
                       startRadius: 0, endRadius: 320)
            .blendMode(.plusLighter)
    }

    private var streak: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: proxy.size.width * 1.4, height: 2)
                .blur(radius: 2.5)
                .rotationEffect(.degrees(-10 + unit(5) * 6))
                .position(x: proxy.size.width / 2, y: proxy.size.height * (0.3 + unit(11) * 0.35))
                .blendMode(.plusLighter)
        }
    }
}

/// Film grain: a few hundred seeded specks, drawn once.
struct Grain: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            var state = UInt64(truncatingIfNeeded: abs(seed) &+ 1) &* 6364136223846793005 &+ 1442695040888963407
            func next() -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return Double(state >> 33) / Double(1 << 31)
            }
            let count = Int(min(size.width * size.height / 260, 1600))
            for _ in 0..<count {
                let rect = CGRect(x: next() * size.width, y: next() * size.height, width: 1.2, height: 1.2)
                context.fill(Path(rect), with: .color(.white.opacity(0.05 + next() * 0.16)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Slowly drifting wall of posters. Fills the background of the sign-in screen so it never sits on empty black.
public struct PosterWall: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public init() {}

    private let tileWidth: CGFloat = 132
    private let tileHeight: CGFloat = 196
    private let gap: CGFloat = 12

    public var body: some View {
        let cycle = (tileHeight + gap) * 6
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .top, spacing: gap) {
                ForEach(0..<5, id: \.self) { column in
                    let speed = 10.0 + Double(column % 3) * 7
                    let direction: Double = column.isMultiple(of: 2) ? -1 : 1
                    let travel = (t * speed).truncatingRemainder(dividingBy: Double(cycle))
                    stack(column: column)
                        .offset(y: direction < 0 ? -CGFloat(travel) - cycle : CGFloat(travel) - cycle * 2)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .rotationEffect(.degrees(-10))
        .scaleEffect(1.25)
        .opacity(0.55)
        .overlay {
            LinearGradient(colors: [Theme.bg.opacity(0.35), Theme.bg.opacity(0.78), Theme.bg], startPoint: .top, endPoint: .bottom)
        }
        .clipped()
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func stack(column: Int) -> some View {
        VStack(spacing: gap) {
            ForEach(0..<13, id: \.self) { row in
                PosterArt(seed: column * 31 + (row % 6) * 7 + 3, lite: true)
                    .frame(width: tileWidth, height: tileHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.rim, lineWidth: 1))
            }
        }
    }
}

public extension View {
    /// A soft band of light that slides across the card as it moves through a scroll view.
    func pulseSheen(strength: Double = 0.2) -> some View {
        overlay {
            LinearGradient(colors: [.clear, .white.opacity(strength), .clear], startPoint: .leading, endPoint: .trailing)
                .rotationEffect(.degrees(18))
                .scaleEffect(x: 0.5, y: 2)
                .blendMode(.plusLighter)
                .visualEffect { content, proxy in
                    let x = proxy.frame(in: .scrollView(axis: .horizontal)).midX / 400
                    return content.offset(x: (x - 0.5) * proxy.size.width * 1.4)
                }
                .allowsHitTesting(false)
        }
    }
}

/// A band of light that sweeps across a button now and then.
struct ShineSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4.5) / 4.5
            let p = reduceMotion ? 2 : min(t / 0.3, 2)
            GeometryReader { proxy in
                LinearGradient(colors: [.clear, .white.opacity(0.32), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: proxy.size.width * 0.45)
                    .rotationEffect(.degrees(20))
                    .offset(x: -proxy.size.width * 0.5 + p * proxy.size.width * 1.5)
                    .blendMode(.plusLighter)
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
