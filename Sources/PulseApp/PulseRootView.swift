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

    public init() { PulseAppearance.apply() }

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
        .environment(\.pulseMediaToken, session.api.sessionToken)
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
        case .signedOut, .signingIn: SignInScreen()
        case .unreachable(let message): UnreachableView(message: message)
        case .unlocked:
            if let stores {
                MainTabView()
                    .environment(stores)
                    .environment(stores.hub)
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
        case .signedOut:
            stores = nil
            coordinator.scene = nil
            coordinator.tonightOpen = false
            coordinator.showLibraries = false
        default: break
        }
    }
}
#endif
