#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign
import PulseFeatures

struct MainTabView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(PlayerCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = self.coordinator
        TabView(selection: $coordinator.tab) {
            Tab(AppTab.home.title, systemImage: "house.fill", value: AppTab.home) { TabStack { HomeView() } }
            Tab(AppTab.library.title, systemImage: "play.rectangle.on.rectangle.fill", value: AppTab.library) { TabStack { LibraryView() } }
            Tab(value: AppTab.search, role: .search) { TabStack { SearchView() } }
            Tab(AppTab.people.title, systemImage: "person.2.fill", value: AppTab.people) { TabStack { PeopleView() } }
            Tab(AppTab.saved.title, systemImage: "heart.fill", value: AppTab.saved) { TabStack { SavedView() } }
            Tab(AppTab.settings.title, systemImage: "gearshape.fill", value: AppTab.settings) { TabStack { SettingsView() } }
        }
        .minimizeTabBarOnScroll()
        .sensoryFeedback(.selection, trigger: coordinator.tab)
        .fullScreenCover(item: $coordinator.scene) { video in
            PlayerContainer(video: video)
        }
        .sheet(isPresented: $coordinator.tonightOpen) { TonightContainer() }
    }
}

private extension View {
    @ViewBuilder
    func minimizeTabBarOnScroll() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) { tabBarMinimizeBehavior(.onScrollDown) } else { self }
        #else
        self
        #endif
    }
}
#endif
