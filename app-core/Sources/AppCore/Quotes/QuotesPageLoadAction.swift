import Foundation

/// Triggers loading the next page of quote search results.
@MainActor
public struct QuotesPageLoadAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    public init(model: QuotesModel) {
        self.init { await model.loadMore() }
    }

    public func callAsFunction() async { await body() }
}
