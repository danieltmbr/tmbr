import SwiftUI

struct MediaEditorView: View {
    let type: CatalogueItemType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("\(type.label) Editor")
                .foregroundStyle(.secondary)
                .navigationTitle(type.label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}
