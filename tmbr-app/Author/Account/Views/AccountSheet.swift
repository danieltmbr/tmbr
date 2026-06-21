import SwiftUI

struct AccountSheet: View {

    @Account(\.isSignedIn)
    private var isSignedIn

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isSignedIn {
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
        .onChange(of: isSignedIn) { _, _ in
            dismiss()
        }
    }
}
