#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign
import PulseFeatures

/// Tabs live in one ZStack so each keeps its scroll position and navigation stack. The bar floats above them.
struct MainTabView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var coordinator
    @State private var visited: Set<AppTab> = [.home]

    private let items: [FloatingTabItem<AppTab>] = [
        .init(.home, title: "Home", icon: "house"),
        .init(.library, title: "Library", icon: "play.rectangle.on.rectangle"),
        .init(.search, title: "Search", icon: "magnifyingglass"),
        .init(.people, title: "People", icon: "person.2"),
        .init(.saved, title: "Saved", icon: "heart"),
    ]

    var body: some View {
        @Bindable var coordinator = self.coordinator
        ZStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                if visited.contains(tab) {
                    let active = tab == coordinator.tab
                    page(tab)
                        .opacity(active ? 1 : 0)
                        .scaleEffect(active ? 1 : 0.97)
                        .blur(radius: active ? 0 : 6)
                        .allowsHitTesting(active)
                        .accessibilityHidden(!active)
                        .zIndex(active ? 1 : 0)
                }
            }
        }
        .animation(.smooth(duration: 0.3), value: coordinator.tab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(items: items, selection: $coordinator.tab)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: coordinator.tab, initial: true) { _, tab in visited.insert(tab) }
        .fullScreenCover(item: $coordinator.scene) { video in
            PlayerContainer(video: video)
        }
        .sheet(isPresented: $coordinator.tonightOpen) { TonightContainer() }
    }

    @ViewBuilder
    private func page(_ tab: AppTab) -> some View {
        switch tab {
        case .home: TabStack { HomeView() }
        case .library: TabStack { LibraryView() }
        case .search: TabStack { SearchView() }
        case .people: TabStack { PeopleView() }
        case .saved: TabStack { SavedView() }
        case .settings: TabStack { SettingsView() }
        }
    }
}
#endif
