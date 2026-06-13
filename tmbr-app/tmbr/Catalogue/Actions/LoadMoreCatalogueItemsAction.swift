import Foundation

@MainActor
public struct LoadMoreCatalogueItemsAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    @MainActor public init(model: CatalogueModel) {
        self.init { await model.loadMoreItems() }
    }

    @MainActor public func callAsFunction() async { await body() }
}
