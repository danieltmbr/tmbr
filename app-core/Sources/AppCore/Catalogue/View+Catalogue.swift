import SwiftUI

public extension View {
    /// Injects the Catalogue model + its refresh and search actions for the tab subtree.
    func catalogue(_ model: CatalogueModel) -> some View {
        environment(model)
            .environment(\.refreshCatalogue, CatalogueRefreshAction(model: model))
            .environment(\.selectCategories, SelectCategoriesAction(model: model))
            .environment(\.searchCatalogue, CatalogueSearchAction(model: model))
            .environment(\.loadCatalogue, CataloguePageLoadAction(model: model))
    }
}
