import Foundation
import Observation

public enum SessionPhase: Equatable, Sendable {
    case booting
    case signedOut
    case signingIn
    case unlocked
    case unreachable(String)
}

/// Where Pulse talks to by default. Users sign in with the same email and password as the Pulse web app.
public enum PulseDefaults {
    public static let serverURL = URL(string: "https://pulse.devxpert.online")!
}

/// Owns the server connection and the signed-in state. One instance for the whole app.
@MainActor
@Observable
public final class AppSession {
    public private(set) var phase: SessionPhase = .booting
    public private(set) var api: any PulseAPI = DemoClient()
    public private(set) var isDemo = false
    public private(set) var info: SessionState?
    public var authError: String?
    public private(set) var email: String

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var lastActive = Date()
    @ObservationIgnored private var autoLockMinutes = 0
    @ObservationIgnored private let serverKey = "pulse.serverURL"
    @ObservationIgnored private let demoKey = "pulse.demo"
    @ObservationIgnored private let emailKey = "pulse.email"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.email = defaults.string(forKey: "pulse.email") ?? ""
    }

    /// The configured server, or the built-in default.
    public var serverURL: URL {
        defaults.string(forKey: serverKey).flatMap(URL.init(string:)) ?? PulseDefaults.serverURL
    }

    public var usesCustomServer: Bool { defaults.string(forKey: serverKey) != nil }

    /// Restore the last session (or demo) and check whether the server still knows us.
    public func boot() async {
        if defaults.bool(forKey: demoKey) { enterDemo(); return }
        api = PulseClient(baseURL: serverURL)
        await refresh()
    }

    public func refresh() async {
        do {
            let state = try await api.session()
            info = state
            phase = state.locked ? .signedOut : .unlocked
        } catch let error as PulseError where error.isLocked {
            phase = .signedOut
        } catch {
            phase = .unreachable(error.asPulseError.errorDescription ?? "Can't reach the server.")
        }
    }

    /// Returns true on success. Failure text lands in `authError`.
    @discardableResult
    public func signIn(email rawEmail: String, password: String) async -> Bool {
        let address = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !address.isEmpty, !password.isEmpty else {
            authError = "Enter your email and password."
            return false
        }
        phase = .signingIn
        do {
            try await api.signIn(email: address, password: password)
            authError = nil
            email = address
            defaults.set(address, forKey: emailKey)
            lastActive = Date()
            info = nil
            await refresh()
            if phase == .unlocked, let settings = try? await api.settings() { autoLockMinutes = settings.autoLockMinutes }
            return phase == .unlocked
        } catch {
            let e = error.asPulseError
            authError = e.errorDescription
            phase = e == .offline ? .unreachable(e.errorDescription ?? "Can't reach the server.") : .signedOut
            return false
        }
    }

    /// Checks the current account's password without changing screens.
    public func verify(password: String) async -> Bool {
        guard !email.isEmpty else { return false }
        do { try await api.signIn(email: email, password: password); return true } catch { return false }
    }

    public func signOut() async {
        try? await api.signOut()
        if isDemo { defaults.set(false, forKey: demoKey); isDemo = false; api = PulseClient(baseURL: serverURL) }
        phase = .signedOut
    }

    public func enterDemo() {
        defaults.set(true, forKey: demoKey)
        isDemo = true
        api = DemoClient()
        info = SessionState(locked: false)
        phase = .unlocked
    }

    /// Advanced: point the app at your own Pulse server instead of the default.
    public func useServer(_ raw: String?) async {
        if let raw, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let url = normalizeServerURL(raw) else { authError = PulseError.invalidServerURL.errorDescription; return }
            defaults.set(url.absoluteString, forKey: serverKey)
        } else {
            defaults.removeObject(forKey: serverKey)
        }
        isDemo = false
        defaults.set(false, forKey: demoKey)
        api = PulseClient(baseURL: serverURL)
        authError = nil
        await refresh()
    }

    /// Server said 423 (session expired): back to the sign-in screen.
    public func serverReportedLocked() { if phase == .unlocked { phase = .signedOut } }

    // MARK: Idle auto sign-out

    public func configureAutoLock(minutes: Int) { autoLockMinutes = minutes }
    public func noteBackgrounded() { lastActive = Date() }

    /// Call when the app returns to the foreground.
    public func noteForegrounded() async {
        guard phase == .unlocked else { return }
        if autoLockMinutes > 0, Date().timeIntervalSince(lastActive) > Double(autoLockMinutes) * 60 {
            await signOut()
        } else {
            await refresh()
        }
    }
}
