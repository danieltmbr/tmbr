import SwiftUI

/// Account toolbar item shown in the tab toolbars.
///
/// Self-gating: renders nothing when `accountStatus` is `.unavailable` (Reader, Personal).
/// Author fills the status from `AccountModel.isSignedIn`.
struct AccountButton: View {

    @Environment(\.accountStatus)
    private var status

    @State
    private var showAccount = false

    var body: some View {
        if status != .unavailable {
            Button {
                showAccount = true
            } label: {
                Image(systemName: status == .signedIn ? "person.circle.fill" : "person.circle")
            }
            .sheet(isPresented: $showAccount) {
                AccountSheet()
            }
        }
    }
}
