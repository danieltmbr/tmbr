import SwiftUI

struct BlogTab: View {
    @Environment(AuthState.self) private var authState
    @State private var showSignIn = false
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(placeholderPosts.enumerated()), id: \.offset) { index, title in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                            Text("May 28")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Blog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if authState.isSignedIn {
                        Button {
                            showEditor = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    } else {
                        Button("Sign In") {
                            showSignIn = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environment(authState)
        }
        .sheet(isPresented: $showEditor) {
            BlogEditorView()
        }
        .onChange(of: authState.isSignedIn) { _, isSignedIn in
            if isSignedIn { showSignIn = false }
        }
    }

    private let placeholderPosts = [
        "On keeping a reading journal",
        "Why I stopped using recommendations",
        "Albums I return to every winter",
        "Notes on Detransition, Baby",
        "The case for private playlists",
    ]
}
