import SwiftUI
import SwiftData
import AppPersistence

/// Displays all filterable catalogue categories (excludes virtual groupings and promotable placeholders).
struct CatalogueCategoriesList: View {

    @Query(sort: \.name)
    private var allCategories: [CatalogueCategoryRecord]

    private var categories: [CatalogueCategoryRecord] {
        allCategories.filter { $0.kind != .virtual && $0.kind != .promotable }
    }

    var body: some View {
        #if os(iOS)
        List(categories) { category in
            CategoryRow(category: category)
                .listRowBackground(Color.clear)
                .listRowSeparator(.automatic)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        #else
        ScrollView {
            VStack(spacing: 0) {
                ForEach(categories) { category in
                    CategoryRow(category: category)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
            }
        }
        #endif
    }
}
