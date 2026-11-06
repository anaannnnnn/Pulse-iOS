#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import AVFoundation
import UIKit
import PulseCore
import PulseDesign

struct PlayerView: View {
    let video: Video
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine = PlayerEngine()
    @State private var model: PlaybackModel
    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var scrubbing = false
    @State private var fill = false
    @State private var hud: HUD?
    @State private var dragOffset: CGFloat = 0
    @State private var startValue: Double = 0
    @State private var upNext: Video?
    @State private var countdown = 8

    struct HUD: Equatable { var symbol: String; var value: Double }

    init(video: Video, api: any PulseAPI) {
        self.video = video
        _model = State(initialValue: PlaybackModel(scene: video, api: api))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                PlayerSurface(engine: engine, fill: fill).ignoresSafeArea()
                    .accessibilityHidden(true)
                if engine.isBuffering, model.phase == .ready { ProgressView().controlSize(.large).tint(.white) }
                subtitleOverlay
                if controlsVisible { controls }
                if let hud { HUDView(hud: hud).transition(.scale.combined(with: .opacity)) }
                stateOverlay
                if let upNext { UpNextCard(video: upNext, countdown: countdown, play: { playNext(upNext) }, cancel: { self.upNext = nil }) }
            }
            .contentShape(Rectangle())
            .gesture(tapGesture(width: proxy.size.width))
            .simultaneousGesture(dragGesture(size: proxy.size))
            .simultaneousGesture(MagnifyGesture().onEnded { value in
                withAnimation(.smooth) { fill = value.magnification > 1.05 ? true : (value.magnification < 0.95 ? false : fill) }
            })
            .offset(y: dragOffset)
            .scaleEffect(1 - min(dragOffset / 1600, 0.08))
            .clipShape(.rect(cornerRadius: dragOffset > 4 ? 28 : 0, style: .continuous))
        }
        .background(Color.black.opacity(1 - min(Double(dragOffset) / 500, 0.7)).ignoresSafeArea())
        .statusBarHidden(!controlsVisible)
        .persistentSystemOverlays(controlsVisible ? .automatic : .hidden)
        .preferredColorScheme(.dark)
        .task { await start() }
        .onDisappear { close(report: true) }
        .onChange(of: scenePhase) { _, phase in if phase == .background { report(force: true) } }
        .onChange(of: engine.isPlaying) { _, playing in
            if playing { scheduleHide() } else { showControls(sticky: true); report(force: true) }
        }
        .onChange(of: engine.hasEnded) { _, ended in if ended { Task { await prepareUpNext() } } }
        .onChange(of: model.rate) { _, rate in engine.applyRate(rate) }
        .sensoryFeedback(.selection, trigger: model.rate)
        .animation(.smooth(duration: 0.25), value: controlsVisible)
        .animation(.snappy, value: hud)
    }

    // MARK: Lifecycle

    private func start() async {
        engine.onFailure = {
            if model.advanceToFallback() { loadCurrent(startAt: engine.currentTime > 5 ? engine.currentTime : model.resumePosition) }
        }
        engine.onTick = { position, duration in
            if !scrubbing { model.report(position: position, duration: duration) }
        }
        await model.prepare()
        loadCurrent(startAt: model.resumePosition)
        scheduleHide()
    }

    private func loadCurrent(startAt: Double) {
        guard let url = model.currentURL else { return }
        let sameHost = url.host == stores.api.baseURL.host
        let cookies = sameHost ? (HTTPCookieStorage.shared.cookies(for: stores.api.baseURL) ?? []) : []
        engine.load(url: url, cookies: cookies, startAt: startAt, rate: model.rate, muted: model.settings.muted)
    }

    private func report(force: Bool = false) {
        guard engine.duration > 0 else { return }
        model.report(position: engine.currentTime, duration: engine.duration, force: force)
    }

    private func close(report doReport: Bool) {
        if doReport { report(force: true) }
        engine.stop()
    }

    // MARK: Up next

    private func prepareUpNext() async {
        report(force: true)
        guard model.settings.autoplayNext else { return }
        var q = LibraryQuery()
        q.sort = .random; q.watched = .false; q.pageSize = 2
        guard let next = try? await stores.api.library(q).items.first(where: { $0.id != video.id }) else { return }
        upNext = next
        countdown = 8
        while countdown > 0, upNext?.id == next.id {
            try? await Task.sleep(for: .seconds(1))
            countdown -= 1
        }
        if upNext?.id == next.id { playNext(next) }
    }

    private func playNext(_ next: Video) {
        upNext = nil
        close(report: false)
        dismiss()
        Task { try? await Task.sleep(for: .milliseconds(450)); coordinator.scene = next }
    }

    // MARK: Gestures

    private func tapGesture(width: CGFloat) -> some Gesture {
        SpatialTapGesture(count: 2).onEnded { value in
            let delta = Double(model.settings.skipSeconds)
            let forward = value.location.x > width / 2
            engine.skip(by: forward ? delta : -delta)
            hud = HUD(symbol: forward ? "goforward" : "gobackward", value: delta)
            Task { try? await Task.sleep(for: .milliseconds(600)); hud = nil }
        }
        .exclusively(before: TapGesture(count: 1).onEnded {
            if controlsVisible { withAnimation { controlsVisible = false } } else { showControls(sticky: false) }
        })
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard !scrubbing, abs(value.translation.height) > abs(value.translation.width) else { return }
                if controlsVisible, value.startLocation.y > size.height - 120 { return }
                let edge = value.startLocation.x
                if edge < size.width * 0.22 {
                    if startValue == 0 { startValue = Double(Self.screen?.brightness ?? 0.5) }
                    let v = min(max(startValue - value.translation.height / (size.height * 0.7), 0), 1)
                    Self.screen?.brightness = CGFloat(v)
                    hud = HUD(symbol: "sun.max.fill", value: v)
                } else if edge > size.width * 0.78 {
                    if startValue == 0 { startValue = max(engine.volume, 0.001) }
                    let v = min(max(startValue - value.translation.height / (size.height * 0.7), 0), 1)
                    engine.setVolume(v)
                    hud = HUD(symbol: v == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill", value: v)
                } else if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                startValue = 0
                hud = nil
                if dragOffset > 140 || value.predictedEndTranslation.height > 420, dragOffset > 20 {
                    dismiss()
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.25)) { dragOffset = 0 }
                }
            }
    }

    private static var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
    }

    // MARK: Controls visibility

    private func showControls(sticky: Bool) {
        withAnimation { controlsVisible = true }
        if !sticky { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled, engine.isPlaying, !scrubbing else { return }
            withAnimation { controlsVisible = false }
        }
    }

    // MARK: Overlays

    @ViewBuilder
    private var subtitleOverlay: some View {
        if let text = model.subtitleText(at: engine.currentTime) {
            VStack {
                Spacer()
                Text(text)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 3)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.black.opacity(0.45), in: .rect(cornerRadius: 10))
                    .padding(.bottom, controlsVisible ? 120 : 40)
                    .padding(.horizontal, 24)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch model.phase {
        case .resolving:
            ProgressView("Preparing…").tint(.white).foregroundStyle(.white).padding(24).pulseGlass()
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(Theme.warning)
                Text(message).foregroundStyle(.white).multilineTextAlignment(.center)
                HStack {
                    Button("Try again") { Task { await start() } }.buttonStyle(.pulsePrimary)
                    Button("Close") { dismiss() }.buttonStyle(.pulseGlass)
                }
            }
            .padding(28).pulseGlass()
        case .ready:
            if engine.hasEnded && upNext == nil {
                VStack(spacing: 14) {
                    Button { engine.toggle() } label: { Label("Replay", systemImage: "arrow.counterclockwise") }.buttonStyle(.pulsePrimary)
                    Button("Close") { dismiss() }.buttonStyle(.pulseGlass)
                }
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.65), .clear, .clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea().allowsHitTesting(false)
            VStack {
                topBar
                Spacer()
                transport
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .transition(.opacity)
    }

    private var topBar: some View {
        PulseGlassGroup(spacing: 10) {
            HStack(spacing: 10) {
                Button { dismiss() } label: { Image(systemName: "chevron.down") }
                    .buttonStyle(.pulseIcon).accessibilityLabel("Minimise player")
                VStack(alignment: .leading, spacing: 1) {
                    Text(video.title).font(PulseFont.label(.subheadline)).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                    if let studio = video.studio?.name { Text(studio).font(.caption).foregroundStyle(.white.opacity(0.7)) }
                }
                Spacer(minLength: 8)
                if engine.pipPossible {
                    Button { engine.togglePiP() } label: { Image(systemName: engine.pipActive ? "pip.exit" : "pip.enter") }
                        .buttonStyle(.pulseIcon).accessibilityLabel("Picture in picture")
                }
                AirPlayButton().frame(width: 44, height: 44).pulseGlass(in: Circle()).accessibilityLabel("AirPlay")
                optionsMenu
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            Menu("Speed", systemImage: "speedometer") {
                Picker("Speed", selection: Binding(get: { model.rate }, set: { model.applySettingsRate($0) })) {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { Text("\($0, format: .number)×").tag($0) }
                }
            }
            if let streams = model.stream, !streams.alternatives.isEmpty {
                Menu("Quality", systemImage: "sparkles.tv") {
                    ForEach(streams.alternatives) { alt in
                        Button(alt.label) {
                            model.selectQuality(alt)
                            loadCurrent(startAt: engine.currentTime)
                        }
                    }
                }
            }
            if let tracks = model.stream?.subtitles, !tracks.isEmpty {
                Menu("Subtitles", systemImage: "captions.bubble") {
                    Button("Off") { Task { await model.selectSubtitle(nil) } }
                    ForEach(tracks) { track in Button(track.label) { Task { await model.selectSubtitle(track) } } }
                }
            }
            Button(fill ? "Fit to screen" : "Fill screen", systemImage: fill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                withAnimation(.smooth) { fill.toggle() }
            }
        } label: { Image(systemName: "ellipsis") }
            .buttonStyle(.pulseIcon)
            .accessibilityLabel("Playback options")
    }

    private var transport: some View {
        let skip = Double(model.settings.skipSeconds)
        return PulseGlassGroup(spacing: 24) {
            HStack(spacing: 28) {
                Button { engine.skip(by: -skip); showControls(sticky: false) } label: { Image(systemName: "gobackward.\(skipSymbol)").font(.system(size: 26, weight: .semibold)) }
                    .buttonStyle(BigIconStyle(size: 64)).accessibilityLabel("Back \(Int(skip)) seconds")
                Button { engine.toggle() } label: {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .bold))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(BigIconStyle(size: 88))
                .accessibilityLabel(engine.isPlaying ? "Pause" : "Play")
                .sensoryFeedback(.impact(weight: .light), trigger: engine.isPlaying)
                Button { engine.skip(by: skip); showControls(sticky: false) } label: { Image(systemName: "goforward.\(skipSymbol)").font(.system(size: 26, weight: .semibold)) }
                    .buttonStyle(BigIconStyle(size: 64)).accessibilityLabel("Forward \(Int(skip)) seconds")
            }
        }
    }

    /// SF Symbols only ship skip glyphs for 5, 10, 15, 30, 45, 60, 75, 90.
    private var skipSymbol: String {
        let allowed = [5, 10, 15, 30, 45, 60, 75, 90]
        let n = model.settings.skipSeconds
        return String(allowed.min(by: { abs($0 - n) < abs($1 - n) }) ?? 10)
    }

    private var bottomBar: some View {
        VStack(spacing: 2) {
            Scrubber(current: engine.currentTime, duration: engine.duration, buffered: engine.bufferedTo,
                     onScrubStart: { scrubbing = true; hideTask?.cancel() },
                     onScrub: { _ in },
                     onScrubEnd: { target in engine.seek(to: target); scrubbing = false; scheduleHide() })
            HStack {
                Text(Format.clock(engine.currentTime)).monospacedDigit()
                Spacer()
                Text("-" + Format.clock(max(engine.duration - engine.currentTime, 0))).monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 2)
            .accessibilityHidden(true)
        }
    }
}

private struct BigIconStyle: ButtonStyle {
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .pulseGlass(in: Circle(), interactive: true)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

private struct HUDView: View {
    let hud: PlayerView.HUD

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: hud.symbol).font(.title).foregroundStyle(.white)
            if hud.symbol.hasPrefix("go") {
                Text("\(Int(hud.value)) s").font(.headline.monospacedDigit()).foregroundStyle(.white)
            } else {
                Capsule().fill(.white.opacity(0.25)).frame(width: 110, height: 6)
                    .overlay(alignment: .leading) { Capsule().fill(Theme.gradient).frame(width: 110 * hud.value, height: 6) }
            }
        }
        .padding(22)
        .pulseGlass()
        .accessibilityHidden(true)
    }
}

private struct UpNextCard: View {
    let video: Video
    let countdown: Int
    let play: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 14) {
                PulseArt(video.poster ?? video.thumb, seed: video.id).frame(width: 110, height: 68)
                    .clipShape(.rect(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Up next in \(countdown)").font(.caption.weight(.semibold)).foregroundStyle(Theme.accentSoft)
                    Text(video.title).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(2)
                }
                Spacer(minLength: 0)
                Button("Play", action: play).buttonStyle(.pulsePrimary)
                Button(action: cancel) { Image(systemName: "xmark") }.buttonStyle(.pulseIcon).accessibilityLabel("Cancel up next")
            }
            .padding(14)
            .pulseGlass()
            .padding(20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
#endif
