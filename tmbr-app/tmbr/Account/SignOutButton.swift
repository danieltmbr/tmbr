import SwiftUI

struct SignOutButton: View {
    
    @Environment(AuthState.self)
    private var authState

    var body: some View {
        Button("Sign Out", role: .destructive) {
            Task { await authState.signOut() }
        }
    }
}

#Preview {
    SignOutButton()
}
