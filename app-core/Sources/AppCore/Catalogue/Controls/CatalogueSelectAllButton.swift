import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

/// Adaptively shows "Select All" or "Deselect All" based on whether every filterable category
/// is currently selected. Uses .override strategy so it replaces the selection in one tap.
struct CatalogueSelectAllButton: View {

    @Query
    private var allCategories: [CatalogueCategoryRecord]

    private var categories: [CatalogueCategoryRecord] {
        allCategories.filter { $0.kind != .virtual && $0.kind != .promotable }
    }

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
