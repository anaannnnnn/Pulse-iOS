#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Main action: solid accent capsule with dark ink on warm accents.
public struct PulsePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(isEnabled ? Theme.onAccent : Theme.textTertiary)
            .padding(.horizontal, 22)
            .frame(minHeight: 50)
            .background(isEnabled ? Theme.accent : Theme.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(isEnabled ? 0.28 : 0.08), lineWidth: 0.8))
            .shadow(color: Theme.accent.opacity(isEnabled ? 0.35 : 0), radius: 14, y: 6)
            .brightness(configuration.isPressed ? -0.12 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Secondary action: Liquid Glass capsule (frosted material before iOS 26).
public struct PulseGlassButtonStyle: ButtonStyle {
    var tint: Color?

    public init(tint: Color? = nil) { self.tint = tint }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .frame(minHeight: 48)
            .pulseCapsuleGlass(tint: tint, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Round glass button. `isOn` tints the glass and symbol.
public struct PulseIconButtonStyle: ButtonStyle {
    var tint: Color?
    var isOn: Bool

    public init(tint: Color? = nil, isOn: Bool = false) { self.tint = tint; self.isOn = isOn }

    public func makeBody(configuration: Configuration) -> some View {
        let color = tint ?? Theme.accent
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isOn ? color : Theme.text)
            .frame(width: 44, height: 44)
            .pulseGlass(in: Circle(), tint: isOn ? color.opacity(0.25) : nil, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .animation(Theme.tap, value: isOn)
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Press feedback for cards and rows: dips and dims a touch.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(Theme.tap, value: configuration.isPressed)
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
    static func pulseIcon(isOn: Bool, tint: Color? = nil) -> PulseIconButtonStyle { .init(tint: tint, isOn: isOn) }
}

public extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { .init() }
}
#endif
