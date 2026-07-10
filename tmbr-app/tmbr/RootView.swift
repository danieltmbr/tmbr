import SwiftUI
import AppCore

/// Author's composition root: hosts the shared `ContentView` and fills the per-app seam —
/// authoring is enabled when signed in, and the account toolbar shows the sign-in/account button.
struct RootView: View {
    @Environment(AuthState.self) private var authState
    // No-op refresh for now — Author's blog/catalogue data-in is its SyncEngine (later stage).
    // Feeds are no-ops automatically: no `apiBaseURL` in the environment → `@Feed` wires no fetch.
    @State private var catalogue = CatalogueModel()
    @State private var quotes = QuotesModel()

    var body: some View {
        ContentView()
            .catalogue(catalogue)
            .quotes(quotes)
            .environment(\.canAuthor, authState.isSignedIn)
            .environment(\.accountToolbar, AccountToolbar { AccountButton() })
    }
}
