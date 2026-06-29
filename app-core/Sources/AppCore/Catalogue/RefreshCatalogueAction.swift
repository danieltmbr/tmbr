import Foundation

/// Refreshes the Catalogue tab — the env-injected seam. One key, a different body per app
/// (Reader fetch+upsert, Author `SyncEngine`, Personal no-op), all funnelled through `CatalogueModel`.
@MainActor
public struct CatalogueRefreshAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    public init(model: CatalogueModel) {
        self.init { await model.refresh() }
    }

    public func callAsFunction() async { await body() }
}
