import SwiftUI

public struct CatalogueFilterView: View {

    @Environment(\.dismiss)
    private var dismiss

    public init() {}

    public var body: some View {
        #if os(iOS)
        NavigationStack {
            List {
                CatalogueCategoriesList()
                LanguageFilterSection()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle("Filter")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        #else
        VStack(spacing: 0) {
            HStack {
                Text("Filter")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            List {
                CatalogueCategoriesList()
                LanguageFilterSection()
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280, height: 360)
        #endif
    }
}
