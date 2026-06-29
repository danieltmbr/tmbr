import AuthenticationServices

/// Signs the user in via Sign in with Apple.
///
/// Unlike most actions the body receives the credential + nonce produced by the SIWA button,
/// so `callAsFunction` takes those parameters instead of the standard `() -> Void` shape.
///
/// The default no-op init is safe to inject in Reader and Personal (they never present `SignInView`).
/// Author extends this type with `init(model:)` to bind it to `AccountModel` — see `Author/Account/`.
@MainActor
public struct SignInAction: Sendable {

    private let body: @MainActor (ASAuthorization, String) -> Void

    /// Default / test path — no-op body.
    nonisolated public init(_ body: @escaping @MainActor (ASAuthorization, String) -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor
    public func callAsFunction(_ authorization: ASAuthorization, nonce: String) {
        body(authorization, nonce)
    }
}
