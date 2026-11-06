#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Round portrait with a violet story ring.
struct PerformerBubble: View {
    let performer: Performer
    var diameter: CGFloat = 78
    @Environment(FavoritesHub.self) private var hub

    var body: some View {
        NavigationLink(value: Route.performer(performer.id)) {
            VStack(spacing: 8) {
                PulseArt(performer.portrait, seed: performer.id)
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
                    .padding(3)
                    .background(Circle().strokeBorder(Theme.gradient, lineWidth: 2.5))
                    .overlay(alignment: .topTrailing) {
                        if hub.isFavorite(performer) {
                            Image(systemName: "heart.fill").font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white).padding(5).background(Theme.accent, in: Circle())
                        }
                    }
                Text(performer.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .frame(width: diameter + 14)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(performer.name), \(performer.sceneCount) scenes")
    }
}

struct PerformerCard: View {
    let performer: Performer
    @Environment(FavoritesHub.self) private var hub

    var body: some View {
        NavigationLink(value: Route.performer(performer.id)) {
            VStack(alignment: .leading, spacing: 8) {
                Color.clear.aspectRatio(3 / 4, contentMode: .fit)
                    .overlay { PulseArt(performer.portrait, seed: performer.id) }
                    .overlay(alignment: .bottom) { LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom) }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(performer.name).font(PulseFont.label(.subheadline)).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                            Text("\(performer.sceneCount) scenes").font(.caption2).foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(12)
                    }
                    .overlay(alignment: .topTrailing) {
                        if hub.isFavorite(performer) {
                            Image(systemName: "heart.fill").font(.caption.weight(.bold)).foregroundStyle(Theme.accentSoft)
                                .padding(7).pulseGlass(in: Circle()).padding(8)
                        }
                    }
                    .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).strokeBorder(Theme.line))
            }
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(performer.name), \(performer.sceneCount) scenes")
    }
}

struct StudioCard: View {
    let studio: Studio

    var body: some View {
        NavigationLink(value: Route.studio(studio.id)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.placeholder(seed: studio.id))
                    if studio.logo != nil { PulseArt(studio.logo, seed: studio.id, contentMode: .fit).padding(6) }
                    else { Text(String(studio.name.prefix(1))).font(PulseFont.display(22)).foregroundStyle(.white.opacity(0.85)) }
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(studio.name).font(PulseFont.label(.body)).fontWeight(.semibold).foregroundStyle(Theme.text)
                    Text("\(studio.sceneCount) scenes").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textTertiary)
            }
            .padding(12)
            .background(Theme.surface.opacity(0.7), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.line))
        }
        .buttonStyle(.pressable)
    }
}
#endif
