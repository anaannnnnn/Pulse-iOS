#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct EditSceneSheet: View {
    let store: SceneStore
    let detail: SceneDetail
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var date: String
    @State private var overview: String
    @State private var studio: String
    @State private var performers: String
    @State private var tags: String

    init(store: SceneStore, detail: SceneDetail) {
        self.store = store
        self.detail = detail
        _title = State(initialValue: detail.scene.title)
        _date = State(initialValue: detail.scene.date ?? "")
        _overview = State(initialValue: detail.description ?? "")
        _studio = State(initialValue: detail.scene.studio?.name ?? "")
        _performers = State(initialValue: detail.performers.map(\.name).joined(separator: ", "))
        _tags = State(initialValue: detail.tags.map(\.name).joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") { TextField("Title", text: $title, axis: .vertical) }
                Section("Release date") {
                    TextField("YYYY-MM-DD", text: $date).keyboardType(.numbersAndPunctuation).autocorrectionDisabled()
                }
                Section("Studio") { TextField("Studio", text: $studio).textInputAutocapitalization(.words) }
                Section("Cast") { TextField("Names separated by commas", text: $performers, axis: .vertical) }
                Section("Tags") { TextField("Tags separated by commas", text: $tags, axis: .vertical).textInputAutocapitalization(.never) }
                Section("Overview") { TextField("Overview", text: $overview, axis: .vertical).lineLimit(3...8) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Edit details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { if await store.edit(makeEdit()) { dismiss() } }
                    }
                    .disabled(store.busy || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .overlay { if store.busy { ProgressView().controlSize(.large) } }
        }
        .presentationDetents([.large])
    }

    private func split(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func makeEdit() -> SceneEdit {
        SceneEdit(title: title.trimmingCharacters(in: .whitespaces),
                  date: date.isEmpty ? nil : date,
                  description: overview,
                  studioName: studio.trimmingCharacters(in: .whitespaces),
                  performerNames: split(performers),
                  tagNames: split(tags))
    }
}
#endif
