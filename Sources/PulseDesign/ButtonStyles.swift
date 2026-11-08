#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Main action: solid crimson, small radius.
public struct PulsePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(minHeight: 46)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay { ShineSweep().clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)) }
            .opacity(isEnabled ? 1 : 0.45)
            .brightness(configuration.isPressed ? -0.12 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Secondary action: translucent grey slab with a thin white rim.
public struct PulseGlassButtonStyle: ButtonStyle {
    var tint: Color?

    public init(tint: Color? = nil) { self.tint = tint }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .frame(minHeight: 46)
            .background((tint ?? Color(white: 0.45)).opacity(tint == nil ? 0.38 : 0.3), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous).strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Round dark button with a thin rim. `isOn` colours the rim and symbol.
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
            .background(.black.opacity(0.45), in: Circle())
            .overlay(Circle().strokeBorder(isOn ? color.opacity(0.9) : .white.opacity(0.55), lineWidth: 1.2))
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
