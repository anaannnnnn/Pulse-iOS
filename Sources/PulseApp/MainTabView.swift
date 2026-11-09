#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign
import PulseFeatures

/// System tab bar: Liquid Glass on iOS 26 (it shrinks as you scroll), a standard bar before that.
struct MainTabView: View {
    @Environment(PlayerCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = self.coordinator
        TabView(selection: $coordinator.tab) {
            Tab(AppTab.home.title, systemImage: "house.fill", value: AppTab.home) { TabStack { HomeView() } }
            Tab(AppTab.library.title, systemImage: "play.square.stack.fill", value: AppTab.library) { TabStack { LibraryView() } }
            Tab(AppTab.people.title, systemImage: "person.2.fill", value: AppTab.people) { TabStack { PeopleView() } }
            Tab(AppTab.saved.title, systemImage: "heart.fill", value: AppTab.saved) { TabStack { SavedView() } }
            Tab(value: AppTab.search, role: .search) { TabStack { SearchView() } }
        }
        .tabBarMinimizeOnScroll()
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: coordinator.tab)
        .fullScreenCover(item: $coordinator.scene) { video in
            PlayerContainer(video: video)
        }
        .sheet(isPresented: $coordinator.settingsOpen) { SettingsContainer() }
        .sheet(isPresented: $coordinator.tonightOpen) { TonightContainer() }
    }
}

private extension View {
    @ViewBuilder
    func tabBarMinimizeOnScroll() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) { tabBarMinimizeBehavior(.onScrollDown) } else { self }
        #else
        self
        #endif
    }
}

/// Settings opens as a sheet from the gear on Home.
struct SettingsContainer: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                }
        }
        .presentationDragIndicator(.visible)
    }
}
#endif
