import SwiftUI

public extension EnvironmentValues {
    /// The account affordance state. Default `.unavailable` — Reader/Personal leave it unset.
    /// Author drives this from `AccountModel.isSignedIn`.
    @Entry var accountStatus: AccountStatus = .unavailable
    /// Triggers Apple Sign In. Author injects a model-bound instance; other targets use the no-op default.
    @Entry var signIn: SignInAction = SignInAction()
    /// Signs the current user out and clears stored credentials.
    @Entry var signOut: SignOutAction = SignOutAction()
}
