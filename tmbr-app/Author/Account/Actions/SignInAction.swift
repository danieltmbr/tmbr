import AuthenticationServices
import OSLog

private let logger = Logger(subsystem: "me.tmbr", category: "auth")

/// Signs the user in via Sign in with Apple.
///
/// Unlike most actions the body receives the credential + nonce produced by the SIWA button,
/// so `callAsFunction` takes those parameters instead of the standard `() -> Void` shape.
@MainActor
public struct SignInAction: Sendable {

    private let body: @MainActor (ASAuthorization, String) -> Void

    /// Default / test path — no-op body.
    nonisolated public init(_ body: @escaping @MainActor (ASAuthorization, String) -> Void = { _, _ in }) {
        self.body = body
    }

    /// Production path — bound to a concrete model.
    @MainActor
    init(model: AccountModel) {
        self.init { authorization, nonce in
            Task {
                do {
                    try await model.signIn(authorization: authorization, nonce: nonce)
                } catch {
                    logger.error("Sign in failed: \(error)")
                }
            }
        }
    }

    @MainActor
    public func callAsFunction(_ authorization: ASAuthorization, nonce: String) {
        body(authorization, nonce)
    }
}
