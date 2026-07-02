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

    public var body: some View {
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

            #if os(macOS)
            VStack(spacing: 0) {
                ForEach(CatalogueItemType.allCases) { type in
                    row(for: type)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
            }
            #else
            List(CatalogueItemType.allCases) { type in
                row(for: type)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            #endif
        }
        #if os(iOS)
        .presentationDetents([.medium])
        .presentationBackground(.ultraThinMaterial)
        #else
        .frame(minWidth: 200)
        #endif
    }

    @ViewBuilder
    private func row(for type: CatalogueItemType) -> some View {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
