#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore

struct RouteDestination: View {
    let route: Route
    @Environment(StoreBundle.self) private var stores
    @Environment(\.zoomNamespace) private var zoomNamespace

    var body: some View {
        switch route {
        case .scene(let video):
            SceneDetailView(video: video, api: stores.api)
                .zoomDestination(id: video.id, in: zoomNamespace)
        case .performer(let id):
            PerformerDetailView(id: id, api: stores.api)
        case .studio(let id):
            StudioDetailView(id: id, api: stores.api)
        case .filtered(let title, let query):
            FilteredLibraryView(title: title, query: query, api: stores.api)
        case .settings(let page):
            SettingsPageView(page: page)
        }
    }
}
#endif
