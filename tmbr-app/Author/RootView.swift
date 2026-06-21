import SwiftUI
import CoreApp

/// Author's composition root: hosts the shared `ContentView` and fills the per-app seam —
/// authoring is enabled when signed in, and the account toolbar shows the sign-in/account button.
struct RootView: View {

    @Account(\.isSignedIn)
    private var isSignedIn

    var body: some View {
        ContentView()
            .environment(\.canAuthor, isSignedIn)
            .environment(\.accountToolbar, AccountToolbar { AccountButton() })
    }
}
