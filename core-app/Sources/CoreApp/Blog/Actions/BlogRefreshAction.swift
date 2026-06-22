import Foundation

/// Refreshes the Blog tab — the env-injected seam. One key, a different body per app
/// (Reader fetch+upsert, Author `SyncEngine`, Personal no-op), all funnelled through `BlogModel`.
@MainActor
public struct BlogRefreshAction: Sendable {

    private let body: @MainActor () async -> Void

    /// Default / test path — no model needed.
    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    /// Production — bound to the screen's model.
    public init(model: BlogModel) {
        self.init { await model.refresh() }
    }

    public func callAsFunction() async { await body() }
}
