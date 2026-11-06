#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

private struct GlassModifier<S: Shape>: ViewModifier {
    let shape: S
    var tint: Color?
    var interactive: Bool

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, macOS 26, *) {
            content.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: shape)
            .background(Color.white.opacity(0.035), in: shape)
            .background((tint ?? .clear).opacity(0.18), in: shape)
            .overlay(shape.strokeBorder(Theme.rim, lineWidth: 1))
    }
}

public extension View {
    /// Liquid Glass on iOS 26+, frosted material with a bright rim before that.
    func pulseGlass<S: Shape>(in shape: S = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous),
                              tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassModifier(shape: shape, tint: tint, interactive: interactive))
    }

    func pulseCapsuleGlass(tint: Color? = nil, interactive: Bool = false) -> some View {
        pulseGlass(in: Capsule(), tint: tint, interactive: interactive)
    }
}

/// Groups nearby glass so shapes can merge and morph on iOS 26+.
public struct PulseGlassGroup<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, macOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
#endif
