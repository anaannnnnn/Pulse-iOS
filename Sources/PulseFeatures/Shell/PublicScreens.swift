#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore

// Public entry points the app target composes. Everything else in this module stays internal.

public struct SignInScreen: View {
    public init() {}
    public var body: some View { SignInView() }
}

public struct PulsePlayerScreen: View {
    let video: Video
    let api: any PulseAPI

    public init(video: Video, api: any PulseAPI) {
        self.video = video
        self.api = api
    }

    public var body: some View { PlayerView(video: video, api: api) }
}

public struct PulseTonightScreen: View {
    public init() {}
    public var body: some View { TonightSheet() }
}

/// Navigation stack that owns the namespace used for zoom transitions into video details.
public struct TabStack<Content: View>: View {
    @Namespace private var namespace
    private let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        NavigationStack { content }
            .environment(\.zoomNamespace, namespace)
    }
}
#endif
