#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

public struct PeopleView: View {
    @Environment(StoreBundle.self) private var stores
    @State private var mode: Mode = .performers
    @State private var studioText = ""

    enum Mode: String, CaseIterable, Identifiable {
        case performers = "Performers", studios = "Studios"
        var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        @Bindable var people = stores.people
        ScrollView {
            VStack(spacing: 18) {
                PulseSegmented(selection: $mode, options: Mode.allCases.map {
                    (value: $0, title: LocalizedStringKey($0.rawValue), icon: nil as String?)
                })
                .padding(.horizontal, Theme.Space.page)

                switch mode {
                case .performers: performers(people)
                case .studios: studios
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .pulseScreenBackground(intensity: 0.5)
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: mode == .performers ? $people.query.text : $studioText, prompt: mode == .performers ? "Search performers" : "Search studios")
        .toolbar {
            if mode == .performers {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $people.query.sort) {
                            ForEach(PerformerQuery.Sort.allCases) { Text($0.label).tag($0) }
                        }
                        Toggle("Favourites only", isOn: $people.query.favoritesOnly)
                    } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }
                }
            }
        }
        .task { await stores.people.loadPerformers(); await stores.people.loadStudios() }
        .task(id: studioText) {
            try? await Task.sleep(for: .milliseconds(280))
            if !Task.isCancelled { await stores.people.loadStudios(text: studioText) }
        }
        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }

    @ViewBuilder
    private func performers(_ people: PeopleStore) -> some View {
        if let error = people.error, people.performers.isEmpty {
            ErrorStateView(error.errorDescription ?? "Couldn't load performers.") { Task { await people.loadPerformers() } }
        } else if people.performers.isEmpty && !people.isLoading {
            EmptyStateView("No performers", message: "Performers appear after your videos are matched.", systemImage: "person.2")
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 14)], spacing: 18) {
                ForEach(people.performers) { performer in
                    PerformerCard(performer: performer)
                        .task { await people.loadMore(current: performer) }
                }
            }
            .padding(.horizontal, Theme.Space.page)
        }
    }

    @ViewBuilder
    private var studios: some View {
        if stores.people.studios.isEmpty {
            EmptyStateView("No studios", message: "Studios appear after your videos are matched.", systemImage: "building.2")
        } else {
            LazyVStack(spacing: 10) {
                ForEach(stores.people.studios) { StudioCard(studio: $0) }
            }
            .padding(.horizontal, Theme.Space.page)
        }
    }
}
#endif
