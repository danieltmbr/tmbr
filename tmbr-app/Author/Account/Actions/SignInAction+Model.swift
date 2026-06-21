import AuthenticationServices
import CoreApp
import OSLog

private let logger = Logger(subsystem: "me.tmbr", category: "auth")

extension SignInAction {

    /// Production path — bound to a concrete `AccountModel`.
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
}
