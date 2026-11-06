#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct PlaybackSettingsView: View {
    @Environment(StoreBundle.self) private var stores

    var body: some View {
        @Bindable var store = stores.settings
        SettingsForm(title: "Playback") {
            Section("Playing") {
                Toggle("Resume where you left off", isOn: $store.settings.playback.resumePlayback)
                Toggle("Autoplay next video", isOn: $store.settings.playback.autoplayNext)
                Toggle("Start muted", isOn: $store.settings.playback.muted)
            }
            Section("Quality") {
                Picker("Default quality", selection: $store.settings.playback.defaultQuality) {
                    ForEach([QualityPreference.auto, .original, .p1080, .p720, .p480]) { Text($0.label).tag($0) }
                }
                Toggle("Prefer adaptive streaming (HLS)", isOn: $store.settings.playback.preferHls)
            }
            Section("Controls") {
                Picker("Skip interval", selection: $store.settings.playback.skipSeconds) {
                    ForEach([5, 10, 15, 30], id: \.self) { Text("\($0) seconds").tag($0) }
                }
                Picker("Speed", selection: $store.settings.playback.playbackRate) {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { Text("\($0, format: .number)×").tag($0) }
                }
            }
            Section("Subtitles") {
                Toggle("Show subtitles when available", isOn: $store.settings.playback.subtitlesEnabled)
            }
        }
        .onChange(of: store.settings.playback) { _, _ in store.scheduleSave() }
        .task { await store.load() }
    }
}
#endif
