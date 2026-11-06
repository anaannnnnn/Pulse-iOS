#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

public struct Shimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.10), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: proxy.size.width * 0.7)
                .offset(x: phase * proxy.size.width * 1.4)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }
}

/// Circular progress with a violet angular gradient.
public struct ProgressRing: View {
    let fraction: Double
    var lineWidth: CGFloat

    public init(_ fraction: Double, lineWidth: CGFloat = 3) {
        self.fraction = fraction
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, fraction))
                .stroke(Theme.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.smooth(duration: 0.6), value: fraction)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}

public struct Chip: View {
    let text: LocalizedStringKey
    var systemImage: String?
    var tint: Color?

    public init(_ text: LocalizedStringKey, systemImage: String? = nil, tint: Color? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let systemImage { Image(systemName: systemImage).font(.caption2.weight(.bold)) }
            Text(text).font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint ?? Theme.text)
        .padding(.horizontal, 10)
        .frame(minHeight: 26)
        .background(.black.opacity(0.35), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.line, lineWidth: 1))
    }
}

public struct SectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: String?
    var action: (() -> Void)?

    public init(_ title: LocalizedStringKey, subtitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
                if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(Theme.textSecondary) }
            }
            .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                Button("See all", action: action)
                    .font(PulseFont.label(.subheadline))
                    .foregroundStyle(Theme.accentSoft)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, Theme.Space.page)
    }
}

public struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    public init(_ title: LocalizedStringKey, message: LocalizedStringKey, systemImage: String,
                actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil) {
        self.title = title; self.message = message; self.systemImage = systemImage
        self.actionTitle = actionTitle; self.action = action
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.accentSoft)
                .padding(22)
                .pulseGlass(in: Circle())
                .symbolEffect(.pulse)
            Text(title).font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.pulsePrimary).padding(.top, 6)
            }
        }
        .frame(maxWidth: 360)
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

public struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    public init(_ message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        EmptyStateView("Something went wrong", message: LocalizedStringKey(message), systemImage: "wifi.exclamationmark",
                       actionTitle: "Try again", action: retry)
    }
}

/// Wide Pulse wordmark with a heartbeat glyph.
public struct PulseMark: View {
    var size: CGFloat
    var showsWordmark: Bool

    public init(size: CGFloat = 28, showsWordmark: Bool = true) {
        self.size = size
        self.showsWordmark = showsWordmark
    }

    public var body: some View {
        HStack(spacing: size * 0.3) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Theme.gradient)
                .symbolEffect(.pulse, options: .repeat(2))
            if showsWordmark {
                Text("PULSE")
                    .font(PulseFont.display(size * 0.8, relativeTo: .title))
                    .tracking(size * 0.14)
                    .foregroundStyle(Theme.text)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pulse")
    }
}

/// Transient message pill.
public struct ToastModifier: ViewModifier {
    @Binding var message: String?

    public func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let text = message {
                Text(text)
                    .font(PulseFont.label(.subheadline))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .pulseCapsuleGlass()
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: text) {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation(.smooth) { message = nil }
                    }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.smooth, value: message)
        .sensoryFeedback(.warning, trigger: message) { _, new in new != nil }
    }
}

public extension View {
    func pulseToast(_ message: Binding<String?>) -> some View { modifier(ToastModifier(message: message)) }

    /// Cards fade and scale as they scroll in/out of view.
    func pulseScrollReveal() -> some View {
        scrollTransition(.animated(.smooth).threshold(.visible(0.15))) { content, phase in
            content.opacity(phase.isIdentity ? 1 : 0.35).scaleEffect(phase.isIdentity ? 1 : 0.92)
        }
    }
}
#endif
