import SwiftUI
import AppPersistence

struct CategoryRow: View {

    let category: CatalogueCategoryRecord

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Environment(\.selectCategories)
    private var selectCategories

    var body: some View {
        Button {
            selectCategories([CatalogueCategory(category)], strategy: .toggle)
        } label: {
            HStack {
                Label(category.name, systemImage: category.icon ?? "link")
                    .foregroundStyle(.primary)
                Spacer()
                if selectedCategories.contains(CatalogueCategory(category)) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
