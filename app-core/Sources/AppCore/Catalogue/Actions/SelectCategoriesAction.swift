import Foundation

@MainActor
public struct SelectCategoriesAction: Sendable {

    private let body: @MainActor (Set<String>, SelectionStrategy) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Set<String>, SelectionStrategy) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: CatalogueModel) {
        self.init { slugs, strategy in
            model.selectedCategorySlugs = strategy.apply(model.selectedCategorySlugs, slugs)
        }
    }

    public func callAsFunction(_ slugs: Set<String>, strategy: SelectionStrategy) {
        body(slugs, strategy)
    }
}
