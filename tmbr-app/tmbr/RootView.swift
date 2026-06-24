import SwiftUI
import CoreApp

/// Author's composition root: hosts the shared `ContentView` and fills the per-app seam —
/// authoring is enabled when signed in, and the account toolbar shows the sign-in/account button.
struct RootView: View {
    @Environment(AuthState.self) private var authState
    // No-op refresh for now — Author's blog/catalogue data-in is its SyncEngine (later stage).
    @State private var blog = BlogModel()
    @State private var catalogue = CatalogueModel()

    var body: some View {
        ContentView()
            .blog(blog)
            .catalogue(catalogue)
            .environment(\.canAuthor, authState.isSignedIn)
            .environment(\.accountToolbar, AccountToolbar { AccountButton() })
    }
}
