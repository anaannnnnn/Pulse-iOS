import SwiftUI

public enum PulseMotion {
    public static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
    public static let gentleSpring = Animation.spring(response: 0.58, dampingFraction: 0.9)
    public static let quick = Animation.easeOut(duration: 0.18)
}

public struct PressScaleEffect: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public var pressedScale: CGFloat = 0.96

    public init(pressedScale: CGFloat = 0.96) {
        self.pressedScale = pressedScale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? pressedScale : 1)
            .animation(PulseMotion.quick, value: configuration.isPressed)
    }
}

public struct StaggeredAppearance: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    public func body(content: Content) -> some View {
        content
            .opacity(visible || reduceMotion ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion ? nil : PulseMotion.gentleSpring.delay(Double(index) * 0.05),
                value: visible
            )
            .onAppear { visible = true }
    }
}

public struct ShimmerEffect: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public func body(content: Content) -> some View {
        Group {
            if reduceMotion {
                content
            } else {
                content
                    .overlay(
                        GeometryReader { proxy in
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.12), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: proxy.size.width * 0.7)
                            .offset(x: phase * proxy.size.width * 1.7)
                            .blendMode(.plusLighter)
                        }
                    )
                    .clipped()
            }
        }
        .onAppear {
            if !reduceMotion { startShimmer() }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            if isReduced {
                withAnimation(.none) { phase = -1 }
            } else {
                startShimmer()
            }
        }
    }

    private func startShimmer() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }
}

public extension View {
    func pulseStaggered(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }

    func pulseShimmer() -> some View {
        modifier(ShimmerEffect())
    }

    func pulsePress(scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressScaleEffect(pressedScale: scale))
    }
}