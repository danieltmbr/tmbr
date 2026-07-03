import Foundation

/// Merges a set of source bucket IDs into `QuotesModel.selectedSources` using a
/// `SelectionStrategy` (`.toggle` for row taps, `.override` for select-all).
@MainActor
public struct SelectQuoteSourcesAction: Sendable {

    private let body: @MainActor (Set<String>, SelectionStrategy) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Set<String>, SelectionStrategy) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: QuotesModel) {
        self.init { sources, strategy in
            model.selectedSources = strategy.apply(model.selectedSources, sources)
        }
    }

    public func callAsFunction(_ sources: Set<String>, strategy: SelectionStrategy) {
        body(sources, strategy)
    }
}
