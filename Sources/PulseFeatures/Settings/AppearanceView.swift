#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseDesign

/// Pick the accent colour. Everything else stays graphite and glass.
struct AppearanceView: View {
    private var store: AccentStore { .shared }

    var body: some View {
        SettingsForm(title: "Appearance") {
            Section {
                HStack(spacing: 12) {
                    ForEach(AccentChoice.allCases) { choice in swatch(choice) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Accent colour")
            } footer: {
                Text("Used for selection, progress and highlights. Surfaces stay neutral.")
            }

            Section("Preview") {
                VStack(alignment: .leading, spacing: 16) {
                    PulseMark(size: 22)
                    HStack(spacing: 8) {
                        Chip("Featured", systemImage: "sparkle", tint: Theme.accentSoft)
                        Chip("4K")
                    }
                    ProgressView(value: 0.62).tint(Theme.accent)
                    Button { } label: { Label("Play", systemImage: "play.fill") }
                        .buttonStyle(.pulsePrimary)
                }
                .padding(.vertical, 8)
                .animation(Theme.tap, value: store.choice)
            }
        }
    }

    private func swatch(_ choice: AccentChoice) -> some View {
        let selected = store.choice == choice
        return Button { store.select(choice) } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(choice.swatch)
                    .frame(width: 40, height: 40)
                    .padding(4)
                    .overlay(Circle().strokeBorder(.white.opacity(selected ? 0.85 : 0), lineWidth: 2))
                    .scaleEffect(selected ? 1.08 : 1)
                Text(choice.title).font(PulseFont.ui(.caption2, weight: .medium)).foregroundStyle(selected ? Theme.text : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(Theme.tap, value: selected)
        .sensoryFeedback(.selection, trigger: selected)
        .accessibilityLabel(Text(choice.title))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
#endif
