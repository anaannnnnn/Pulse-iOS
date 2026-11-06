#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Mint pill with a glow. Dark label, soft top highlight, springy press.
public struct PulsePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.label(.headline))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 26)
            .frame(minHeight: 52)
            .background(Theme.gradient, in: Capsule())
            .overlay {
                Capsule().fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center)).blendMode(.overlay)
            }
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.8))
            .shadow(color: Theme.accent.opacity(configuration.isPressed ? 0.18 : 0.5), radius: configuration.isPressed ? 6 : 20, y: configuration.isPressed ? 3 : 9)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// White pill with a dark label, for the main action on photographic backgrounds.
public struct PulseLightButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.label(.headline))
            .foregroundStyle(Color(hex: 0x0A0C0D))
            .padding(.horizontal, 24)
            .frame(minHeight: 50)
            .background(LinearGradient(colors: [.white, Color(hex: 0xDDE3E1)], startPoint: .top, endPoint: .bottom), in: Capsule())
            .shadow(color: .white.opacity(configuration.isPressed ? 0.05 : 0.22), radius: configuration.isPressed ? 4 : 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

public struct PulseGlassButtonStyle: ButtonStyle {
    var tint: Color?

    public init(tint: Color? = nil) { self.tint = tint }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.label(.subheadline))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .frame(minHeight: 48)
            .pulseCapsuleGlass(tint: tint)
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Round 46pt icon button on glass. `isOn` fills it with the accent (favourite, saved).
public struct PulseIconButtonStyle: ButtonStyle {
    var tint: Color?
    var isOn: Bool

    public init(tint: Color? = nil, isOn: Bool = false) { self.tint = tint; self.isOn = isOn }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isOn ? Theme.onAccent : Theme.text)
            .frame(width: 46, height: 46)
            .background {
                if isOn { Circle().fill(tint.map { AnyShapeStyle($0) } ?? AnyShapeStyle(Theme.gradient)).shadow(color: (tint ?? Theme.accent).opacity(0.5), radius: 12) }
            }
            .pulseGlass(in: Circle(), tint: isOn ? nil : tint)
            .scaleEffect(configuration.isPressed ? 0.84 : 1)
            .animation(Theme.tap, value: configuration.isPressed)
            .animation(Theme.tap, value: isOn)
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// Press feedback for cards and rows: dips, tilts a hair and dims.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .rotation3DEffect(.degrees(configuration.isPressed ? 2.5 : 0), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(Theme.tap, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PulsePrimaryButtonStyle {
    static var pulsePrimary: PulsePrimaryButtonStyle { .init() }
}

public extension ButtonStyle where Self == PulseLightButtonStyle {
    static var pulseLight: PulseLightButtonStyle { .init() }
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
