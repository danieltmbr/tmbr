import SwiftUI

struct BlogTab: View {
    @Environment(AuthState.self) private var authState
    @State private var showAccount = false
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(placeholderPosts.enumerated()), id: \.offset) { index, title in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
#if os(macOS)
                        Text(title)
                        Spacer()
                        Text("May 28")
                            .foregroundStyle(.secondary)
#else
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                            Text("May 28")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
#endif
                    }
                }
            }
            .navigationTitle("Blog")
            .toolbar {
#if os(iOS)
                if authState.isSignedIn {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showEditor = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#else
                if authState.isSignedIn {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showEditor = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAccount = true
                    } label: {
                        Image(systemName: authState.isSignedIn ? "person.circle.fill" : "person.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showAccount) {
            AccountSheet()
                .environment(authState)
        }
        .sheet(isPresented: $showEditor) {
            BlogEditorView()
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
