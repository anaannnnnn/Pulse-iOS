#if canImport(SwiftUI) && canImport(UIKit)
import Observation
import SwiftUI
import PulseCore

public enum Route: Hashable {
    case scene(Video)
    case performer(Int)
    case studio(Int)
    case filtered(title: String, query: LibraryQuery)
    case settings(SettingsPage)
}

public enum SettingsPage: String, Hashable, CaseIterable {
    case playback, privacy, pcloud, torbox, matching, sources, data, about
}

/// Presents the full-screen player from anywhere in the app.
@MainActor
@Observable
public final class PlayerCoordinator {
    public var scene: Video?
    public var tonightOpen = false
    public var tab: AppTab = .home

    public init() {}

    public func play(_ scene: Video) { self.scene = scene }
}

public enum AppTab: String, Hashable, CaseIterable, Sendable {
    case home, library, search, people, saved, settings

    public var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .search: "Search"
        case .people: "People"
        case .saved: "Saved"
        case .settings: "Settings"
        }
    }

    public var symbol: String {
        switch self {
        case .home: "house.fill"
        case .library: "play.rectangle.on.rectangle.fill"
        case .search: "magnifyingglass"
        case .people: "person.2.fill"
        case .saved: "heart.fill"
        case .settings: "gearshape.fill"
        }
    }
}

extension EnvironmentValues {
    @Entry var zoomNamespace: Namespace.ID?
}

extension View {
    /// Marks a view as the source of a navigation zoom transition when a namespace is available.
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace { matchedTransitionSource(id: id, in: namespace) } else { self }
    }

    @ViewBuilder
    func zoomDestination(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace { navigationTransition(.zoom(sourceID: id, in: namespace)) } else { self }
    }
}
#endif
