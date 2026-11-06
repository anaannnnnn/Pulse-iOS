import Foundation
import Observation

public enum SessionPhase: Equatable, Sendable {
    case booting
    case needsServer
    case connecting
    case locked
    case unlocked
    case unreachable(String)
}

/// Owns the active server connection and lock state. One instance for the whole app.
@MainActor
@Observable
public final class AppSession {
    public private(set) var phase: SessionPhase = .booting
    public private(set) var api: any PulseAPI = DemoClient()
    public private(set) var isDemo = false
    public private(set) var info: SessionState?
    public var pinError: String?
    public private(set) var lockoutUntil: Date?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var lastActive = Date()
    @ObservationIgnored private var autoLockMinutes = 0
    @ObservationIgnored private let serverKey = "pulse.serverURL"
    @ObservationIgnored private let demoKey = "pulse.demo"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var serverURL: URL? {
        defaults.string(forKey: serverKey).flatMap(URL.init(string:))
    }

    /// Restore the last server (or demo) and check whether it is locked.
    public func boot() async {
        if defaults.bool(forKey: demoKey) { enterDemo(); return }
        guard let url = serverURL else { phase = .needsServer; return }
        api = PulseClient(baseURL: url)
        await refresh()
    }

    public func connect(to raw: String) async {
        guard let url = normalizeServerURL(raw) else { pinError = PulseError.invalidServerURL.errorDescription; return }
        phase = .connecting
        let candidate = PulseClient(baseURL: url)
        do {
            _ = try await candidate.health()
            defaults.set(url.absoluteString, forKey: serverKey)
            defaults.set(false, forKey: demoKey)
            isDemo = false
            api = candidate
            pinError = nil
            await refresh()
        } catch {
            phase = .needsServer
            pinError = error.asPulseError.errorDescription
        }
    }

    public func enterDemo() {
        defaults.set(true, forKey: demoKey)
        isDemo = true
        api = DemoClient()
        info = SessionState(locked: false)
        phase = .locked
    }

    public func forgetServer() {
        defaults.removeObject(forKey: serverKey)
        defaults.set(false, forKey: demoKey)
        isDemo = false
        info = nil
        phase = .needsServer
    }

    public func refresh() async {
        do {
            let state = try await api.session()
            info = state
            phase = state.locked ? .locked : .unlocked
        } catch let error as PulseError where error.isLocked {
            phase = .locked
        } catch {
            phase = .unreachable(error.asPulseError.errorDescription ?? "Can't reach the server.")
        }
    }

    /// Returns true on success. Failure text lands in `pinError`.
    @discardableResult
    public func unlock(pin: String) async -> Bool {
        do {
            try await api.unlock(pin: pin)
            pinError = nil
            lockoutUntil = nil
            lastActive = Date()
            if isDemo { info = SessionState(locked: false); phase = .unlocked } else { await refresh() }
            if let settings = try? await api.settings() { autoLockMinutes = settings.autoLockMinutes }
            return phase == .unlocked
        } catch let error as PulseError {
            pinError = error.errorDescription
            if case .rateLimited(let wait) = error { lockoutUntil = Date().addingTimeInterval(wait ?? 60) }
            return false
        } catch {
            pinError = error.asPulseError.errorDescription
            return false
        }
    }

    public func lock() async {
        try? await api.lock()
        phase = .locked
    }

    /// Server said 423: drop back to the keypad.
    public func serverReportedLocked() { if phase == .unlocked { phase = .locked } }

    // MARK: Idle auto-lock

    public func configureAutoLock(minutes: Int) { autoLockMinutes = minutes }
    public func noteBackgrounded() { lastActive = Date() }

    /// Call when the app returns to the foreground.
    public func noteForegrounded() async {
        guard phase == .unlocked else { return }
        if autoLockMinutes > 0, Date().timeIntervalSince(lastActive) > Double(autoLockMinutes) * 60 {
            await lock()
        }
    }
}
