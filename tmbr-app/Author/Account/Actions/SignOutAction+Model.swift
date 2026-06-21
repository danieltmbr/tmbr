import CoreApp

extension SignOutAction {

    /// Production path — bound to a concrete `AccountModel`.
    @MainActor
    init(model: AccountModel) {
        self.init {
            Task { await model.signOut() }
        }
    }
}
