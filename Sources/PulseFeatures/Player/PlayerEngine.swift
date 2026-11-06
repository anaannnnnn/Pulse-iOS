#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import AVFoundation
import AVKit
import Combine
import Observation

/// AVPlayer wrapper: time, buffering, PiP, route changes. All UI-facing state lives here.
@MainActor
@Observable
final class PlayerEngine: NSObject, AVPictureInPictureControllerDelegate {
    let player = AVPlayer()
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var bufferedTo: Double = 0
    private(set) var isPlaying = false
    private(set) var isBuffering = true
    private(set) var hasEnded = false
    private(set) var pipActive = false
    private(set) var pipPossible = false
    private(set) var rate: Double = 1

    @ObservationIgnored var onFailure: (() -> Void)?
    @ObservationIgnored var onTick: ((Double, Double?) -> Void)?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var bag = Set<AnyCancellable>()
    @ObservationIgnored private var itemBag = Set<AnyCancellable>()
    @ObservationIgnored private var pip: AVPictureInPictureController?
    @ObservationIgnored private var pendingStart: Double = 0

    override init() {
        super.init()
        player.allowsExternalPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
        configureAudioSession()
        installTimeObserver()
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.isPlaying = status != .paused
                self.isBuffering = status == .waitingToPlayAtSpecifiedRate
            }
            .store(in: &bag)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [])
        try? session.setActive(true)
    }

    private func installTimeObserver() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                let seconds = time.seconds
                guard seconds.isFinite else { return }
                self.currentTime = seconds
                if let item = self.player.currentItem {
                    let d = item.duration.seconds
                    if d.isFinite, d > 0 { self.duration = d }
                    if let range = item.loadedTimeRanges.first?.timeRangeValue { self.bufferedTo = range.end.seconds }
                }
                self.onTick?(seconds, self.duration > 0 ? self.duration : nil)
            }
        }
    }

    // MARK: Loading

    func load(url: URL, cookies: [HTTPCookie], token: String?, startAt: Double, rate: Double, muted: Bool) {
        itemBag.removeAll()
        hasEnded = false
        isBuffering = true
        pendingStart = startAt
        self.rate = rate
        player.isMuted = muted

        var options: [String: Any] = [:]
        if !cookies.isEmpty { options[AVURLAssetHTTPCookiesKey] = cookies }
        // Segments and sub-playlists do not inherit `?pt=`, so send the token as a header too.
        if let token { options["AVURLAssetHTTPHeaderFieldsKey"] = ["Authorization": "Bearer \(token)"] }
        let asset = AVURLAsset(url: url, options: options.isEmpty ? nil : options)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 0
        item.audioTimePitchAlgorithm = .timeDomain

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    let d = item.duration.seconds
                    if d.isFinite, d > 0 { self.duration = d }
                    if self.pendingStart > 0 {
                        let start = self.pendingStart
                        self.pendingStart = 0
                        self.player.seek(to: CMTime(seconds: start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                            Task { @MainActor in self.play() }
                        }
                    } else { self.play() }
                case .failed: self.onFailure?()
                default: break
                }
            }
            .store(in: &itemBag)

        NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.hasEnded = true; self?.isPlaying = false }
            .store(in: &itemBag)

        NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onFailure?() }
            .store(in: &itemBag)

        player.replaceCurrentItem(with: item)
    }

    // MARK: Transport

    func applyRate(_ value: Double) {
        rate = value
        if isPlaying { player.rate = Float(value) }
    }

    func play() { hasEnded = false; player.playImmediately(atRate: Float(rate)) }
    func pause() { player.pause() }
    func toggle() { if isPlaying { pause() } else { if hasEnded { seek(to: 0) }; play() } }

    func seek(to seconds: Double) {
        let target = min(max(seconds, 0), duration > 0 ? duration : seconds)
        currentTime = target
        hasEnded = false
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func skip(by delta: Double) { seek(to: currentTime + delta) }
    func setVolume(_ value: Double) { player.volume = Float(min(max(value, 0), 1)); if value > 0 { player.isMuted = false } }
    var volume: Double { Double(player.volume) }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let timeObserver { player.removeTimeObserver(timeObserver); self.timeObserver = nil }
        itemBag.removeAll()
        pip?.stopPictureInPicture()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Picture in picture

    func attach(layer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported(), pip == nil else { return }
        let controller = AVPictureInPictureController(playerLayer: layer)
        controller?.delegate = self
        controller?.canStartPictureInPictureAutomaticallyFromInline = true
        pip = controller
        controller?.publisher(for: \.isPictureInPicturePossible)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] possible in self?.pipPossible = possible }
            .store(in: &bag)
    }

    func togglePiP() {
        guard let pip else { return }
        if pip.isPictureInPictureActive { pip.stopPictureInPicture() } else { pip.startPictureInPicture() }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.pipActive = true }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.pipActive = false }
    }
}
#endif
