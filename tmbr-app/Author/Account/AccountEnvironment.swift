import SwiftUI

public extension EnvironmentValues {
    /// Triggers Apple Sign In. Reads the credential and nonce produced by `SignInView`.
    @Entry var signIn: SignInAction = SignInAction()
    /// Signs the current user out and clears stored credentials.
    @Entry var signOut: SignOutAction = SignOutAction()
}
