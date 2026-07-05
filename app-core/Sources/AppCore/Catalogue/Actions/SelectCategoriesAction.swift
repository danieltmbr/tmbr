import Foundation
import AppPersistence

@MainActor
public struct SelectCategoriesAction: Sendable {

    private let body: @MainActor (Set<CatalogueCategory>, SelectionStrategy<CatalogueCategory>) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Set<CatalogueCategory>, SelectionStrategy<CatalogueCategory>) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: CatalogueModel) {
        self.init { categories, strategy in
            model.selectedCategories = strategy.apply(model.selectedCategories, categories)
        }
    }

    public func callAsFunction(_ categories: Set<CatalogueCategory>, strategy: SelectionStrategy<CatalogueCategory>) {
        body(categories, strategy)
    }
}
