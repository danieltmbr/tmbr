import SwiftUI
import AppPersistence

struct CategoryRow: View {

    let category: CatalogueCategoryRecord

    @Catalogue(\.selectedCategorySlugs)
    private var selectedSlugs

    @Environment(\.selectCategories)
    private var selectCategories

    var body: some View {
        Button {
            selectCategories([category.categorySlug], strategy: .toggle)
        } label: {
            HStack {
                Label(category.name, systemImage: category.icon ?? "link")
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSlugs.contains(category.categorySlug) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
