import SwiftUI

struct AccountSheet: View {
    
    @Environment(AuthState.self)
    private var authState
    
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if authState.isSignedIn {
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
        .onChange(of: authState.isSignedIn) { _, _ in
            dismiss()
        }
    }
}
