import SwiftUI

struct AccountSheet: View {

    @Environment(\.accountStatus)
    private var status

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if status == .signedIn {
                    AccountView()
                } else {
                    SignInView()
                }
            }
            .navigationTitle("Account")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 380)
        .onChange(of: status) { old, new in
            // Auto-dismiss when sign-in / sign-out completes
            if old != new { dismiss() }
        }
    }
}
