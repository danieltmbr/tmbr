import Foundation

/// Fires a quotes search for `term` — the env-injected seam for per-tab text search.
@MainActor
public struct QuotesSearchAction: Sendable {

    private let body: @MainActor (String) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (String) async -> Void = { _ in }) {
        self.body = body
    }

    public init(model: QuotesModel) {
        self.init { term in await model.search(term: term) }
    }

    public func callAsFunction(term: String) async { await body(term) }
}
