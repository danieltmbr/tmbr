import SwiftUI

struct AccountSheet: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if authState.isSignedIn {
                    VStack(spacing: 24) {
                        Spacer()
                        Button("Sign Out", role: .destructive) {
                            Task { await authState.signOut() }
                        }
                        .padding(.bottom, 60)
                    }
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
