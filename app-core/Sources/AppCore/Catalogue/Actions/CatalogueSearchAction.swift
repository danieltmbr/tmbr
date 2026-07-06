import Foundation

/// Fires a catalogue search for `term` — the env-injected seam for per-tab text search.
@MainActor
public struct CatalogueSearchAction: Sendable {

    private let body: @MainActor (String) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (String) async -> Void = { _ in }) {
        self.body = body
    }

    public init(model: CatalogueModel) {
        self.init { term in await model.search(term: term) }
    }

    public func callAsFunction(term: String) async { await body(term) }
}
