import Foundation

/// Signs the current user out and clears stored credentials.
@MainActor
public struct SignOutAction: Sendable {

    private let body: @MainActor () -> Void

    /// Default / test path — no-op body.
    nonisolated public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    /// Production path — bound to a concrete model.
    @MainActor
    init(model: AccountModel) {
        self.init {
            Task { await model.signOut() }
        }
    }

    @MainActor
    public func callAsFunction() { body() }
}
