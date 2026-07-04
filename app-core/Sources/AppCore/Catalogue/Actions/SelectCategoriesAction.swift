import Foundation
import AppPersistence

@MainActor
public struct SelectCategoriesAction: Sendable {

    private let body: @MainActor (Set<CategorySlug>, SelectionStrategy<CategorySlug>) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Set<CategorySlug>, SelectionStrategy<CategorySlug>) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: CatalogueModel) {
        self.init { slugs, strategy in
            model.selectedCategorySlugs = strategy.apply(model.selectedCategorySlugs, slugs)
        }
    }

    public func callAsFunction(_ slugs: Set<CategorySlug>, strategy: SelectionStrategy<CategorySlug>) {
        body(slugs, strategy)
    }
}
