import SwiftUI

public struct CatalogueFilterView: View {
    @Binding var selectedTypes: Set<CatalogueItemType>
    @Environment(\.dismiss) private var dismiss

    public init(selectedTypes: Binding<Set<CatalogueItemType>>) {
        self._selectedTypes = selectedTypes
    }

    private var allSelected: Bool {
        selectedTypes.count == CatalogueItemType.allCases.count
    }

    private func toggle(_ type: CatalogueItemType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    public var body: some View {
        #if os(iOS)
        NavigationStack {
            List(CatalogueItemType.allCases) { type in
                Button { toggle(type) } label: {
                    HStack {
                        Label(type.label, systemImage: type.systemImage)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle("Filter")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
        .presentationDetents([.medium, .large])
        #else
        VStack(spacing: 0) {
            HStack {
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        selectedTypes.removeAll()
                    } else {
                        selectedTypes = Set(CatalogueItemType.allCases)
                    }
                }
                Spacer()
                Text("Filter")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(CatalogueItemType.allCases) { type in
                        Button { toggle(type) } label: {
                            HStack {
                                Label(type.label, systemImage: type.systemImage)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                    }
                }
            }
        }
        .frame(minWidth: 200, maxHeight: 400)
        #endif
    }
}
