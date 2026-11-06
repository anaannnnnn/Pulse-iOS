#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct FilterSheet: View {
    @Binding var query: LibraryQuery
    @Environment(StoreBundle.self) private var stores
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Show") {
                    Toggle("Favourites only", isOn: $query.favoritesOnly)
                    Toggle("Watchlist only", isOn: $query.watchlistOnly)
                    Picker("Progress", selection: $query.watched) {
                        ForEach(WatchedFilter.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Source", selection: sourceBinding) {
                        Text("Any").tag(SceneSource?.none)
                        Text("pCloud").tag(SceneSource?.some(.pcloud))
                        Text("TorBox").tag(SceneSource?.some(.torbox))
                    }
                    Picker("Metadata", selection: matchedBinding) {
                        Text("Any").tag(Int(0))
                        Text("Matched").tag(Int(1))
                        Text("Unmatched").tag(Int(2))
                    }
                }
                if let facets = stores.library.facets {
                    yearSection(facets)
                    Section("Length") {
                        Picker("Length", selection: lengthBinding) {
                            Text("Any").tag(0)
                            Text("Under 20 min").tag(1)
                            Text("20–45 min").tag(2)
                            Text("Over 45 min").tag(3)
                        }
                    }
                    if !facets.studios.isEmpty {
                        multiSection("Studios", items: facets.studios.map { ($0.id, $0.name) }, selection: $query.studioIDs)
                    }
                    if !facets.performers.isEmpty {
                        multiSection("Performers", items: facets.performers.map { ($0.id, $0.name) }, selection: $query.performerIDs)
                    }
                    if !facets.tags.isEmpty {
                        multiSection("Tags", items: facets.tags.map { ($0.id, $0.name) }, selection: $query.tagIDs)
                    }
                } else {
                    Section { ProgressView().frame(maxWidth: .infinity) }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Reset") { query.clearFilters() }.disabled(query.activeFilterCount == 0) }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { await stores.library.loadFacets() }
        }
    }

    private var sourceBinding: Binding<SceneSource?> { Binding(get: { query.source }, set: { query.source = $0 }) }

    private var matchedBinding: Binding<Int> {
        Binding(get: { query.matched == nil ? 0 : (query.matched == true ? 1 : 2) },
                set: { query.matched = $0 == 0 ? nil : ($0 == 1) })
    }

    private var lengthBinding: Binding<Int> {
        Binding(get: {
            switch (query.minDuration, query.maxDuration) {
            case (nil, 1200?): 1
            case (1200?, 2700?): 2
            case (2700?, nil): 3
            default: 0
            }
        }, set: {
            switch $0 {
            case 1: query.minDuration = nil; query.maxDuration = 1200
            case 2: query.minDuration = 1200; query.maxDuration = 2700
            case 3: query.minDuration = 2700; query.maxDuration = nil
            default: query.minDuration = nil; query.maxDuration = nil
            }
        })
    }

    @ViewBuilder
    private func yearSection(_ facets: LibraryFacets) -> some View {
        let years = facets.years.map(\.year).sorted()
        if let first = years.first, let last = years.last, first != last {
            Section("Year") {
                Picker("From", selection: Binding(get: { query.yearFrom ?? first }, set: { query.yearFrom = $0 == first ? nil : $0 })) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }
                Picker("To", selection: Binding(get: { query.yearTo ?? last }, set: { query.yearTo = $0 == last ? nil : $0 })) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }
            }
        }
    }

    private func multiSection(_ title: LocalizedStringKey, items: [(Int, String)], selection: Binding<[Int]>) -> some View {
        Section(title) {
            DisclosureGroup("\(selection.wrappedValue.count) selected") {
                ForEach(items, id: \.0) { id, name in
                    Button {
                        if let i = selection.wrappedValue.firstIndex(of: id) { selection.wrappedValue.remove(at: i) }
                        else { selection.wrappedValue.append(id) }
                    } label: {
                        HStack {
                            Text(name).foregroundStyle(Theme.text)
                            Spacer()
                            if selection.wrappedValue.contains(id) { Image(systemName: "checkmark").foregroundStyle(Theme.accentSoft) }
                        }
                    }
                    .accessibilityAddTraits(selection.wrappedValue.contains(id) ? .isSelected : [])
                }
            }
        }
    }
}
#endif
