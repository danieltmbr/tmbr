import SwiftUI

public struct MediaTypePickerSheet: View {
    let onSelect: (CatalogueItemType) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onSelect: @escaping (CatalogueItemType) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            List(CatalogueItemType.allCases) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    Label(type.label, systemImage: type.systemImage)
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("New Item")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
