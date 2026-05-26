import SwiftUI

struct ContentView: View {
    @Environment(AuthState.self) private var authState

    var body: some View {
        if authState.isSignedIn {
            HomeView()
        } else {
            SignInView()
        }
    }
}

private struct HomeView: View {
    @Environment(AuthState.self) private var authState

    var body: some View {
        NavigationStack {
            Text("Welcome to tmbr")
                .navigationTitle("tmbr")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Sign Out") { authState.signOut() }
                    }
                }
        }
    }
}
