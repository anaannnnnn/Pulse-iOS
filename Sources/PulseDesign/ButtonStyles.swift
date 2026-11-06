#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

public struct PulsePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.label(.headline))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .frame(minHeight: 50)
            .background(Theme.gradient, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.28), lineWidth: 1))
            .shadow(color: Theme.accent.opacity(configuration.isPressed ? 0.15 : 0.45), radius: configuration.isPressed ? 6 : 18, y: 8)
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.22), value: configuration.isPressed)
    }
}

public struct PulseGlassButtonStyle: ButtonStyle {
    var tint: Color?

    public init(tint: Color? = nil) { self.tint = tint }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.label(.subheadline))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .pulseCapsuleGlass(tint: tint)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Round 44pt icon button on glass.
public struct PulseIconButtonStyle: ButtonStyle {
    var tint: Color?

    public init(tint: Color? = nil) { self.tint = tint }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.text)
            .frame(width: 44, height: 44)
            .pulseGlass(in: Circle(), tint: tint)
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Subtle press feedback for cards and rows.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PulsePrimaryButtonStyle {
    static var pulsePrimary: PulsePrimaryButtonStyle { .init() }
}

public extension ButtonStyle where Self == PulseGlassButtonStyle {
    static var pulseGlass: PulseGlassButtonStyle { .init() }
    static func pulseGlass(tint: Color?) -> PulseGlassButtonStyle { .init(tint: tint) }
}

public extension ButtonStyle where Self == PulseIconButtonStyle {
    static var pulseIcon: PulseIconButtonStyle { .init() }
}

public extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { .init() }
}
#endif
