import SwiftUI
import SwiftData
import AppPersistence

/// Displays all filterable catalogue categories (excludes virtual groupings and promotable
/// placeholders) as a `Section` for embedding in a parent `List`.
struct CatalogueCategoriesList: View {

    @Query(sort: \CatalogueCategoryRecord.name)
    private var allCategories: [CatalogueCategoryRecord]

    private var categories: [CatalogueCategoryRecord] {
        allCategories.filter { $0.kind != .virtual && $0.kind != .promotable }
    }

    var body: some View {
        Section {
            ForEach(categories) { category in
                CategoryRow(category: category)
                    .listRowBackground(Color.clear)
            }
        } header: {
            HStack {
                Text("Categories")
                Spacer()
                CatalogueSelectAllButton()
            }
        }
    }
}
