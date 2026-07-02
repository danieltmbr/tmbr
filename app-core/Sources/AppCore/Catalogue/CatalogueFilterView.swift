import SwiftUI

public struct CatalogueFilterView: View {
    @Binding var selectedTypes: Set<CatalogueItemType>
    @Environment(\.dismiss) private var dismiss

    public init(selectedTypes: Binding<Set<CatalogueItemType>>) {
        self._selectedTypes = selectedTypes
    }

    public var body: some View {
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
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Filter")
            .toolbarTitleDisplayMode(.inline)
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
        .presentationDetents([.medium])
        .frame(minWidth: 320, minHeight: 380)
    }
}
