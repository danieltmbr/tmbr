import Foundation

/// Fires a blog search for `term` — the env-injected seam for per-tab text search.
///
/// One key, a different body per app (Reader fetch+upsert, Author no-op, Personal no-op),
/// all funnelled through `BlogModel.search(term:)`.
@MainActor
public struct BlogSearchAction: Sendable {

    private let body: @MainActor (String) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (String) async -> Void = { _ in }) {
        self.body = body
    }

    public init(model: BlogModel) {
        self.init { term in await model.search(term: term) }
    }

    public func callAsFunction(term: String) async { await body(term) }
}
