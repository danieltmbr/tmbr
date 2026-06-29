import Foundation

/// Loads the next page of Blog posts — the env-injected seam. Same shape as `RefreshBlogAction`:
/// a no-op default + a model-bound production init, callable as a function.
@MainActor
public struct BlogPageLoadAction: Sendable {

    private let body: @MainActor () async -> Void

    /// Default / test path — no model needed.
    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    /// Production — bound to the screen's model.
    public init(model: BlogModel) {
        self.init { await model.loadMore() }
    }

    public func callAsFunction() async { await body() }
}
