import SwiftUI

public struct ImmersiveSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    public init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(PulseFont.title(.title2))
                    .foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accentSoft)
                }
                .pulsePress()
            }
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, 8)
    }
}

public struct ImmersiveMediaCard: View {
    let title: String
    var subtitle: String?
    var poster: Image?
    var progress: Double?

    public init(title: String, subtitle: String? = nil, poster: Image? = nil, progress: Double? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.poster = poster
        self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.gradient)
                    .overlay(Color.black.opacity(0.42))
                    .frame(height: 210)

                if let poster {
                    poster
                        .resizable()
                        .scaledToFill()
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(1)
                    }
                }
                .padding(14)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .immersiveGlow(.blue)

            if let progress {
                ImmersiveProgressBar(progress: progress)
            }
        }
        .pulsePress(scale: 0.97)
    }
}

public struct ImmersiveRatingPill: View {
    let text: String
    var icon: String = "star.fill"

    public init(text: String, icon: String = "star.fill") {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.surface.opacity(0.9)))
        .overlay(Capsule().strokeBorder(Theme.lineStrong))
    }
}

public struct ImmersiveProgressBar: View {
    let progress: Double

    public init(progress: Double) {
        self.progress = max(0, min(1, progress))
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                Capsule()
                    .fill(Theme.gradient)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 4)
        .animation(PulseMotion.spring, value: progress)
    }
}

public struct ImmersiveEmptyState: View {
    let icon: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Theme.accentSoft)
                .immersiveGlow(Theme.accent)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent.opacity(0.18)))
                }
                .pulsePress()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

public struct ImmersiveSectionDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(
                LinearGradient(colors: [.clear, Theme.lineStrong, .clear], startPoint: .leading, endPoint: .trailing)
            )
            .frame(height: 1)
            .padding(.vertical, 10)
    }
}