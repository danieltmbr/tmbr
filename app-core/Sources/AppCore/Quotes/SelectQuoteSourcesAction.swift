import Foundation
import AppPersistence

/// Merges a set of source filters into `QuotesModel.selectedSources` using a
/// `SelectionStrategy` (`.toggle` for row taps, `.override` for select-all).
@MainActor
public struct SelectQuoteSourcesAction: Sendable {

    private let body: @MainActor (Set<QuoteSourceFilter>, SelectionStrategy<QuoteSourceFilter>) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Set<QuoteSourceFilter>, SelectionStrategy<QuoteSourceFilter>) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: QuotesModel) {
        self.init { sources, strategy in
            model.selectedSources = strategy.apply(model.selectedSources, sources)
        }
    }

    public func callAsFunction(_ sources: Set<QuoteSourceFilter>, strategy: SelectionStrategy<QuoteSourceFilter>) {
        body(sources, strategy)
    }
}
