#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Rounded play triangle.
struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Arc that radiates from the tip of the triangle, like a signal.
struct SignalArc: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.minX, y: rect.midY), radius: radius, startAngle: .degrees(-42), endAngle: .degrees(42), clockwise: false)
        return p
    }
}

/// The Pulse glyph: a play triangle sending out two signal arcs.
public struct PulseGlyph: View {
    var size: CGFloat
    var animated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(size: CGFloat = 28, animated: Bool = true) {
        self.size = size
        self.animated = animated
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let a1 = animated && !reduceMotion ? 0.55 + 0.45 * sin(t * 2.4) : 0.9
            let a2 = animated && !reduceMotion ? 0.35 + 0.35 * sin(t * 2.4 - 0.9) : 0.5
            ZStack {
                PlayTriangle()
                    .fill(LinearGradient(colors: [.white, .white.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                    .overlay(PlayTriangle().stroke(.white, style: StrokeStyle(lineWidth: size * 0.12, lineJoin: .round)))
                    .frame(width: size * 0.42, height: size * 0.5)
                    .offset(x: -size * 0.2)
                SignalArc(radius: size * 0.2)
                    .stroke(Theme.accentSoft.opacity(a1), style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round))
                    .frame(width: 1, height: 1)
                    .offset(x: size * 0.08)
                SignalArc(radius: size * 0.34)
                    .stroke(Theme.accent.opacity(a2), style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round))
                    .frame(width: 1, height: 1)
                    .offset(x: size * 0.08)
            }
            .frame(width: size, height: size)
        }
        .accessibilityHidden(true)
    }
}

/// Wordmark: the projector glyph beside a serif "Pulse". `showsWordmark: false` gives the glyph alone.
public struct PulseMark: View {
    var size: CGFloat
    var showsWordmark: Bool

    public init(size: CGFloat = 28, showsWordmark: Bool = true) {
        self.size = size
        self.showsWordmark = showsWordmark
    }

    public var body: some View {
        HStack(spacing: size * 0.18) {
            PulseGlyph(size: showsWordmark ? size * 1.5 : size * 1.6)
            if showsWordmark {
                Text("Pulse")
                    .font(.system(size: size * 1.35, weight: .semibold, design: .serif))
                    .tracking(-size * 0.02)
                    .foregroundStyle(Theme.text)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pulse")
    }
}
#endif
