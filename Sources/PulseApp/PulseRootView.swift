#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign
import PulseFeatures

/// The whole app. The Xcode target only needs `WindowGroup { PulseRootView() }`.
public struct PulseRootView: View {
    @State private var session = AppSession()
    @State private var stores: StoreBundle?
    @State private var coordinator = PlayerCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            phaseContent
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            if shieldVisible { PrivacyShield().transition(.opacity).zIndex(10) }
        }
        .animation(.smooth(duration: 0.4), value: session.phase)
        .animation(.smooth(duration: 0.2), value: shieldVisible)
        .environment(session)
        .environment(coordinator)
        .environment(\.pulseImageBase, session.api.baseURL)
        .environment(\.pulseBlurArt, stores?.settings.settings.blurThumbnails ?? false)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .task { await session.boot() }
        .onChange(of: session.phase) { _, phase in handle(phase) }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: session.noteBackgrounded()
            case .active: Task { await session.noteForegrounded() }
            default: break
            }
        }
    }

    private var shieldVisible: Bool {
        scenePhase != .active && session.phase == .unlocked && (stores?.settings.settings.hideFromRecents ?? false)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch session.phase {
        case .booting: SplashView()
        case .needsServer, .connecting: ServerSetupScreen()
        case .locked: LockScreen()
        case .unreachable(let message): UnreachableView(message: message)
        case .unlocked:
            if let stores {
                MainTabView()
                    .environment(stores)
            } else {
                SplashView()
            }
        }
    }

    private func handle(_ phase: SessionPhase) {
        switch phase {
        case .unlocked:
            if stores == nil { stores = StoreBundle(api: session.api) }
            Task {
                await stores?.settings.load()
                if let minutes = stores?.settings.settings.autoLockMinutes { session.configureAutoLock(minutes: minutes) }
            }
        case .needsServer:
            stores = nil
            coordinator.scene = nil
        case .locked:
            coordinator.scene = nil
            coordinator.tonightOpen = false
        default: break
        }
    }
}
#endif
