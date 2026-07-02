import SwiftUI
import SwiftData
import AppPersistence

/// Adaptively shows "Select All" or "Deselect All" based on whether every filterable category
/// is currently selected. Uses .override strategy so it replaces the selection in one tap.
struct CatalogueSelectAllButton: View {

    private static let virtual = CatalogueCategoryKind.virtual.rawValue
    private static let promotable = CatalogueCategoryKind.promotable.rawValue

    @Query(
        filter: #Predicate<CatalogueCategoryRecord> {
            $0.kindRaw != CatalogueSelectAllButton.virtual &&
            $0.kindRaw != CatalogueSelectAllButton.promotable
        }
    )
    private var categories: [CatalogueCategoryRecord]

    @Catalogue(\.selectedCategorySlugs)
    private var selectedSlugs

    @Environment(\.selectCategories)
    private var selectCategories

    private var allSelected: Bool {
        !categories.isEmpty && categories.allSatisfy { selectedSlugs.contains($0.slug) }
    }

    var body: some View {
        Button(allSelected ? "Deselect All" : "Select All") {
            let slugs = allSelected ? [] : Set(categories.map(\.slug))
            selectCategories(slugs, strategy: .override)
        }
    }
}
