import SwiftUI

public struct ImmersiveBackground: View {
    let colors: [Color]

    public init(colors: [Color] = [
        Theme.bg,
        Color(hex: 0x11152A),
        Color(hex: 0x090A16)
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
                colors: [Color(hex: 0x617DFF).opacity(0.2), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 620
            )
        )
        .overlay(
            RadialGradient(
                colors: [Color(hex: 0xA178EF).opacity(0.16), .clear],
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
            .padding(Theme.Space.page)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(Theme.surface.opacity(0.58), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .strokeBorder(Theme.rim.opacity(0.72), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.34), radius: 26, y: 14)
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