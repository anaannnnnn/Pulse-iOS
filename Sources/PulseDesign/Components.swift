#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

public struct Shimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.09), .clear], startPoint: .leading, endPoint: .trailing)
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

/// Circular progress with a mint gradient.
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
        .padding(.horizontal, 12)
        .frame(minHeight: 28)
        .pulseCapsuleGlass()
    }
}

/// Small count pill next to a heading ("Collections 8").
public struct CountBadge: View {
    let value: Int

    public init(_ value: Int) { self.value = value }

    public var body: some View {
        Text(value, format: .number)
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(Theme.text)
            .contentTransition(.numericText())
            .padding(.horizontal, 9)
            .frame(minHeight: 24)
            .background(.white.opacity(0.12), in: Capsule())
            .animation(Theme.tap, value: value)
    }
}

/// Sliding-pill segmented control (replaces the stock segmented Picker).
public struct PulseSegmented<Value: Hashable>: View {
    let options: [(value: Value, title: LocalizedStringKey, icon: String?)]
    @Binding var selection: Value
    @Namespace private var pill

    public init(selection: Binding<Value>, options: [(value: Value, title: LocalizedStringKey, icon: String?)]) {
        self._selection = selection
        self.options = options
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let selected = option.value == selection
                Button {
                    withAnimation(Theme.glide) { selection = option.value }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = option.icon { Image(systemName: icon).font(.caption.weight(.bold)) }
                        Text(option.title).font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(selected ? Theme.text : Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background {
                        if selected {
                            Capsule().fill(.white.opacity(0.16))
                                .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.8))
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .pulseCapsuleGlass()
        .sensoryFeedback(.selection, trigger: selection)
    }
}

public struct SectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: String?
    var count: Int?
    var action: (() -> Void)?

    public init(_ title: LocalizedStringKey, subtitle: String? = nil, count: Int? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title).font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
                    if let count { CountBadge(count) }
                }
                if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(Theme.textSecondary) }
            }
            .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                Button(action: action) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 40, height: 40)
                        .pulseGlass(in: Circle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("See all")
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
                .pulseGlass(in: Circle(), tint: Theme.accent.opacity(0.15))
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

    /// Cards fade, scale and sink slightly as they scroll in/out of view.
    func pulseScrollReveal() -> some View {
        scrollTransition(.animated(.smooth).threshold(.visible(0.15))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.3)
                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                .blur(radius: phase.isIdentity ? 0 : 3)
        }
    }

    /// Curved carousel: neighbours swing away on a Y axis and shrink, like the category cards in the references.
    func pulseCurvedCarousel(angle: Double = 24) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            content
                .rotation3DEffect(.degrees(phase.value * -angle), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                .scaleEffect(1 - abs(phase.value) * 0.1)
                .offset(x: phase.value * -14)
                .opacity(1 - abs(phase.value) * 0.35)
        }
    }

    /// Slowly rotating mint highlight around a shape's edge. Static under Reduce Motion.
    func pulseGlowBorder<S: InsettableShape>(_ shape: S, lineWidth: CGFloat = 1.4) -> some View {
        modifier(GlowBorder(shape: shape, lineWidth: lineWidth))
    }
}

private struct GlowBorder<S: InsettableShape>: ViewModifier {
    let shape: S
    let lineWidth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                let angle = reduceMotion ? 30 : (context.date.timeIntervalSinceReferenceDate * 40).truncatingRemainder(dividingBy: 360)
                shape.strokeBorder(
                    AngularGradient(colors: [.clear, Theme.accent.opacity(0.9), .white.opacity(0.9), .clear, .clear], center: .center, angle: .degrees(angle)),
                    lineWidth: lineWidth)
            }
            .allowsHitTesting(false)
        }
    }
}

/// Number that counts up from zero the first time it appears.
public struct CountUpText: View {
    let value: Int
    var compact: Bool
    @State private var shown = 0

    public init(_ value: Int, compact: Bool = false) {
        self.value = value
        self.compact = compact
    }

    public var body: some View {
        Text(shown, format: compact ? .number.notation(.compactName) : .number)
            .contentTransition(.numericText(value: Double(shown)))
            .task(id: value) {
                withAnimation(.smooth(duration: 1.1)) { shown = value }
            }
    }
}
#endif
