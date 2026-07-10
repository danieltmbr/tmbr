import Foundation

/// Loads the next page of the active feed session — the env-injected seam behind
/// `FeedLoadMoreCell`. Wired by `.feedControls(_:retry:)` to the owning feed's `loadMore()`.
@MainActor
public struct FeedPageLoadAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    public func callAsFunction() async { await body() }
}
