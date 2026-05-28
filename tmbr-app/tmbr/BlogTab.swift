import SwiftUI

struct BlogTab: View {
    @Environment(AuthState.self) private var authState
    @State private var searchText = ""
    @State private var showSignIn = false
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<5) { i in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Post Title \(i + 1)")
                            .font(.headline)
                        Text("A short excerpt from the post...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Blog")
            .searchable(text: $searchText)
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
        }
        .fullScreenCover(isPresented: $showEditor) {
            BlogEditorView()
        }
        .tabItem {
            Label("Blog", systemImage: "doc.text")
        }
    }
}
