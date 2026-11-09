#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// "What should I watch tonight?" Pick how long you have and get three unwatched suggestions.
struct TonightSheet: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var player
    @Environment(\.dismiss) private var dismiss
    @State private var length: Length = .any
    @State private var picks: [Video] = []
    @State private var loading = false

    enum Length: String, CaseIterable, Identifiable {
        case short = "Quick", medium = "Evening", long = "Long", any = "Surprise me"
        var id: String { rawValue }
        var range: (min: Double?, max: Double?) {
            switch self {
            case .short: (nil, 1200)
            case .medium: (1200, 2700)
            case .long: (2700, nil)
            case .any: (nil, nil)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How long do you have?").font(PulseFont.headline(.title2)).foregroundStyle(Theme.text)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                        ForEach(Length.allCases) { option in
                            Button { withAnimation(Theme.tap) { length = option } } label: {
                                Text(LocalizedStringKey(option.rawValue)).lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.pulseGlass(tint: length == option ? Theme.accent.opacity(0.45) : nil))
                            .accessibilityAddTraits(length == option ? .isSelected : [])
                        }
                    }

                    if loading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if picks.isEmpty {
                        EmptyStateView("Nothing to suggest", message: "You've watched everything that fits. Try another length.", systemImage: "sparkles")
                    } else {
                        ForEach(picks) { video in
                            Button { dismiss(); player.play(video) } label: { TonightRow(video: video) }.buttonStyle(.pressable)
                        }
                        Button("Shuffle again", systemImage: "dice") { Task { await load() } }
                            .buttonStyle(.pulseGlass)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(Theme.Space.page)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Tonight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task(id: length) { await load() }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground { AuroraBackground(intensity: 0.9) }
    }

    private func load() async {
        loading = true
        var q = LibraryQuery()
        q.sort = .random
        q.watched = .false
        q.minDuration = length.range.min
        q.maxDuration = length.range.max
        q.pageSize = 3
        picks = (try? await stores.api.library(q).items) ?? []
        loading = false
    }
}

private struct TonightRow: View {
    let video: Video

    var body: some View {
        HStack(spacing: 14) {
            PulseArt(video.poster ?? video.thumb, seed: video.id)
                .frame(width: 128, height: 80)
                .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay { Image(systemName: "play.fill").foregroundStyle(.white).frame(width: 36, height: 36).pulseGlass(in: Circle()) }
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title).font(PulseFont.ui(.subheadline, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(2)
                Text([video.studio?.name, Format.runtime(video.duration)].compactMap { $0 }.joined(separator: " · "))
                    .font(PulseFont.ui(.caption)).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Plays now")
    }
}
#endif
