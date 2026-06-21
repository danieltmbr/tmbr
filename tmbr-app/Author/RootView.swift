import SwiftUI
import CoreApp

/// Author's composition root: hosts the shared `ContentView` and fills the per-app seam —
/// authoring is enabled when signed in, and the account status drives the account button.
struct RootView: View {

    @Account(\.isSignedIn)
    private var isSignedIn

    var body: some View {
        ContentView()
            .environment(\.canAuthor, isSignedIn)
            .environment(\.accountStatus, isSignedIn ? .signedIn : .signedOut)
    }
}
