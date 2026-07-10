import SwiftUI

public extension View {
    /// Injects the Catalogue filter model + its category-selection action for the tab subtree.
    func catalogue(_ model: CatalogueModel) -> some View {
        environment(model)
            .environment(\.selectCategories, SelectCategoriesAction(model: model))
    }
}
