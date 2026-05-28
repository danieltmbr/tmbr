import SwiftUI

struct CatalogueFilterSheet: View {
    @Binding var selectedTypes: Set<CatalogueItemType>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(CatalogueItemType.allCases) { type in
                Button {
                    if selectedTypes.contains(type) {
                        selectedTypes.remove(type)
                    } else {
                        selectedTypes.insert(type)
                    }
                } label: {
                    HStack {
                        Label(type.label, systemImage: type.systemImage)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    let allSelected = selectedTypes.count == CatalogueItemType.allCases.count
                    Button(allSelected ? "Deselect All" : "Select All") {
                        if allSelected {
                            selectedTypes.removeAll()
                        } else {
                            selectedTypes = Set(CatalogueItemType.allCases)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
