import Foundation

/// Loads the next page of catalogue search results — the env-injected seam for search pagination.
@MainActor
public struct CataloguePageLoadAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    public init(model: CatalogueModel) {
        self.init { await model.loadMore() }
    }

    public func callAsFunction() async { await body() }
}
