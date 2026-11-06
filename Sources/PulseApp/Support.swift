#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign
import PulseFeatures

struct SplashView: View {
    @State private var breathe = false

    var body: some View {
        ZStack {
            AuroraBackground()
            PulseMark(size: 52)
                .scaleEffect(breathe ? 1.04 : 0.96)
                .shadow(color: Theme.accent.opacity(breathe ? 0.6 : 0.2), radius: 30)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: breathe)
        }
        .onAppear { breathe = true }
    }
}

struct UnreachableView: View {
    let message: String
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            AuroraBackground()
            EmptyStateView("Can't reach your server", message: LocalizedStringKey(message), systemImage: "wifi.slash",
                           actionTitle: "Try again") { Task { await session.refresh() } }
            VStack {
                Spacer()
                Button("Sign out") { Task { await session.signOut() } }.buttonStyle(.pulseGlass).padding(.bottom, 40)
            }
        }
    }
}

/// Covers the app in the app switcher when "Hide in app switcher" is on.
struct PrivacyShield: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThickMaterial)
            Theme.bg.opacity(0.92)
            PulseMark(size: 40)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct PlayerContainer: View {
    let video: Video
    @Environment(StoreBundle.self) private var stores

    var body: some View { PulsePlayerScreen(video: video, api: stores.api) }
}

struct TonightContainer: View {
    var body: some View { PulseTonightScreen() }
}
#endif
