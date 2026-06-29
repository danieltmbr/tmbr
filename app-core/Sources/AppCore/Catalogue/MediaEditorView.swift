import SwiftUI

public struct MediaEditorView: View {
    let type: CatalogueItemType
    @Environment(\.dismiss) private var dismiss

    public init(type: CatalogueItemType) {
        self.type = type
    }

    public var body: some View {
        NavigationStack {
            Text("\(type.label) Editor")
                .foregroundStyle(.secondary)
                .navigationTitle(type.label)
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}
