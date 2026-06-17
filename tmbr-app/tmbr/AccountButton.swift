import SwiftUI

/// Author's account toolbar item — the app-specific content injected into the shared tabs'
/// `accountToolbar` slot. Reader injects nothing.
struct AccountButton: View {
    @Environment(AuthState.self) private var authState
    @State private var showAccount = false

    var body: some View {
        Button {
            showAccount = true
        } label: {
            Image(systemName: authState.isSignedIn ? "person.circle.fill" : "person.circle")
        }
        .sheet(isPresented: $showAccount) {
            AccountSheet()
                .environment(authState)
        }
    }
}
