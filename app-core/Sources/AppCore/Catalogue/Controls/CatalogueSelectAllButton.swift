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

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Environment(\.selectCategories)
    private var selectCategories

    private var allSelected: Bool {
        !categories.isEmpty && categories.allSatisfy { selectedCategories.contains(CatalogueCategory($0)) }
    }

    var body: some View {
        Button(allSelected ? "Deselect All" : "Select All") {
            let selection: Set<CatalogueCategory> = allSelected ? [] : Set(categories.map(CatalogueCategory.init))
            selectCategories(selection, strategy: .override)
        }
    }
}
