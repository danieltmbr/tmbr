import SwiftUI

/// Overlay shown when the post list is empty, switching on the current load state.
struct BlogEmptyView: View {

    @Blog(\.loading)
    private var activeLoad

    @Blog(\.lastError)
    private var lastError

    @Environment(\.refreshBlog)
    private var refreshBlog

    var body: some View {
        if activeLoad == .refresh {
            ProgressView()
        } else if let error = lastError {
            ContentUnavailableView {
                Label(error.title, systemImage: error.systemImage)
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") { Task { await refreshBlog() } }
            }
        } else {
            ContentUnavailableView("No posts yet", systemImage: "doc.text")
        }
    }
}
