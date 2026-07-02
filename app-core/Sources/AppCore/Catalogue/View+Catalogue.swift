import SwiftUI

public extension View {
    /// Injects the Catalogue model + its refresh action for the tab subtree.
    func catalogue(_ model: CatalogueModel) -> some View {
        environment(model)
            .environment(\.refreshCatalogue, CatalogueRefreshAction(model: model))
            .environment(\.selectCategories, SelectCategoriesAction(model: model))
    }
}
