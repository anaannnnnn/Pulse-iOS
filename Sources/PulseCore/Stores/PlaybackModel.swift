import Foundation
import Observation

/// Playback logic independent of AVFoundation: source fallback, resume point, progress reporting, subtitles.
@MainActor
@Observable
public final class PlaybackModel {
    public enum Phase: Equatable { case resolving, ready, failed(String) }

    public private(set) var phase: Phase = .resolving
    public private(set) var stream: StreamInfo?
    public private(set) var cues: [SubtitleCue] = []
    public private(set) var currentSourceIndex = 0
    public var activeSubtitle: SubtitleTrack?
    public var rate: Double = 1
    public var quality: QualityPreference = .auto

    public let scene: Video
    @ObservationIgnored private let api: any PulseAPI
    @ObservationIgnored private var sources: [URL] = []
    @ObservationIgnored private var lastReported: Double = -100
    @ObservationIgnored public private(set) var settings = PlaybackSettings()

    public init(scene: Video, api: any PulseAPI) {
        self.scene = scene
        self.api = api
    }

    public var resumePosition: Double {
        guard settings.resumePlayback, let p = scene.progress, !p.completed, p.position > 5 else { return 0 }
        return max(p.position - 3, 0)
    }

    public var currentURL: URL? { sources.indices.contains(currentSourceIndex) ? sources[currentSourceIndex] : nil }
    public var hasFallback: Bool { currentSourceIndex + 1 < sources.count }
    public var qualityOptions: [StreamAlternative] { stream?.alternatives ?? [] }

    public func prepare() async {
        phase = .resolving
        if let s = try? await api.settings() {
            settings = s.playback
            rate = s.playback.playbackRate
            quality = s.playback.defaultQuality
        }
        do {
            let info = try await api.stream(sceneID: scene.id)
            stream = info
            sources = info.candidates(preferring: quality, preferHLS: settings.preferHls).compactMap { api.absoluteURL($0) }
            currentSourceIndex = 0
            guard !sources.isEmpty else { phase = .failed("No playable source."); return }
            phase = .ready
            if settings.subtitlesEnabled, let track = pickSubtitle(info.subtitles) { await selectSubtitle(track) }
        } catch {
            phase = .failed(error.asPulseError.errorDescription ?? "Couldn't start playback.")
        }
    }

    /// Player reported an error: step to the next source (direct link -> HLS -> server proxy).
    @discardableResult
    public func advanceToFallback() -> Bool {
        guard hasFallback else { phase = .failed("This file can't be played."); return false }
        currentSourceIndex += 1
        return true
    }

    public func selectQuality(_ q: StreamAlternative) {
        guard let url = api.absoluteURL(q.url) else { return }
        sources.insert(url, at: currentSourceIndex)
    }

    public func selectSubtitle(_ track: SubtitleTrack?) async {
        activeSubtitle = track
        guard let track else { cues = []; return }
        cues = (try? await api.subtitleCues(for: track)) ?? []
    }

    public func subtitleText(at time: Double) -> String? {
        guard activeSubtitle != nil else { return nil }
        return WebVTT.cue(at: time, in: cues)?.text
    }

    private func pickSubtitle(_ tracks: [SubtitleTrack]) -> SubtitleTrack? {
        if let lang = settings.subtitleLang, let match = tracks.first(where: { $0.lang == lang }) { return match }
        return tracks.first
    }

    /// Throttled: sends progress at most every 15 s unless forced (pause, close, end).
    public func report(position: Double, duration: Double?, force: Bool = false) {
        guard position.isFinite, position >= 0 else { return }
        if !force, abs(position - lastReported) < 15 { return }
        lastReported = position
        let finished = duration.map { $0 > 0 && position / $0 >= 0.92 }
        let api = self.api, id = scene.id
        Task { try? await api.saveProgress(sceneID: id, position: position, duration: duration, completed: finished) }
    }

    public func applySettingsRate(_ newRate: Double) { rate = newRate }
}
