import SwiftUI

struct SignOutButton: View {

    @Environment(\.signOut)
    private var signOut

    var body: some View {
        Button("Sign Out", role: .destructive) {
            signOut()
        }
    }
}

#Preview {
    SignOutButton()
        .environment(\.signOut, SignOutAction())
}
