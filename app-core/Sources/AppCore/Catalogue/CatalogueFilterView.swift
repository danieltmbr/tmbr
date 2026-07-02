import SwiftUI

public struct CatalogueFilterView: View {

    @Environment(\.dismiss)
    private var dismiss

    public init() {}

    public var body: some View {
        #if os(iOS)
        NavigationStack {
            CatalogueCategoriesList()
                .navigationTitle("Filter")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CatalogueSelectAllButton()
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
                CatalogueSelectAllButton()
                Spacer()
                Text("Filter")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            CatalogueCategoriesList()
        }
        .frame(minWidth: 200, maxHeight: 400)
        #endif
    }
}
