import SwiftUI

public struct ImmersiveBackground: View {
    let colors: [Color]

    public init(colors: [Color] = [
        Color(red: 0.04, green: 0.05, blue: 0.08),
        Color(red: 0.08, green: 0.09, blue: 0.16),
        Color(red: 0.03, green: 0.04, blue: 0.07)
    ]) {
        self.colors = colors
    }

    public var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [.blue.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 620
            )
        )
        .overlay(
            RadialGradient(
                colors: [.purple.opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 540
            )
        )
        .ignoresSafeArea()
    }
}

public struct ImmersiveCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.28), radius: 22, y: 12)
    }
}

public struct AccentGlow: ViewModifier {
    let color: Color

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.35), radius: 18, y: 6)
    }
}

public extension View {
    func immersiveGlow(_ color: Color = .blue) -> some View {
        modifier(AccentGlow(color: color))
    }
}