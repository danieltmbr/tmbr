import SwiftUI

/// Author's account toolbar item — injected into the shared tabs' `accountToolbar` slot.
/// Shows a person icon that opens the account sheet. Reader injects nothing here.
struct AccountButton: View {

    @Account(\.isSignedIn)
    private var isSignedIn

    @State
    private var showAccount = false

    var body: some View {
        Button {
            showAccount = true
        } label: {
            Image(systemName: isSignedIn ? "person.circle.fill" : "person.circle")
        }
        .sheet(isPresented: $showAccount) {
            AccountSheet()
        }
    }
}
