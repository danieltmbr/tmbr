/// Signs the current user out and clears stored credentials.
///
/// The default no-op init is safe in Reader and Personal. Author extends this type with
/// `init(model:)` — see `Author/Account/`.
@MainActor
public struct SignOutAction: Sendable {

    private let body: @MainActor () -> Void

    /// Default / test path — no-op body.
    nonisolated public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    public func callAsFunction() { body() }
}
