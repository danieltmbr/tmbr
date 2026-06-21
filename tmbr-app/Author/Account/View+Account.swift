import SwiftUI
import CoreApp

extension View {
    /// Injects the account model and its actions into the environment.
    /// Call once on the Author app's root view.
    func account(_ model: AccountModel) -> some View {
        environment(model)
            .environment(\.signIn, SignInAction(model: model))
            .environment(\.signOut, SignOutAction(model: model))
    }
}
