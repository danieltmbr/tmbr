import SwiftUI
import SwiftData
import AppPersistence

/// Displays all filterable catalogue categories (excludes virtual groupings and promotable placeholders).
struct CatalogueCategoriesList: View {

    private static let virtual = CatalogueCategoryKind.virtual.rawValue
    private static let promotable = CatalogueCategoryKind.promotable.rawValue

    @Query(
        filter: #Predicate<CatalogueCategoryRecord> {
            $0.kindRaw != CatalogueCategoriesList.virtual &&
            $0.kindRaw != CatalogueCategoriesList.promotable
        },
        sort: \.name
    )
    private var categories: [CatalogueCategoryRecord]

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
