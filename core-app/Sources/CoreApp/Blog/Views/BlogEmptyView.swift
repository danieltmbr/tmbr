import SwiftUI

/// Overlay shown when the post list is empty, switching on the current load phase.
struct BlogEmptyView: View {

    @Blog(\.phase)
    private var phase

    var body: some View {
        switch phase {
        case .loading:
            ProgressView()
        case .failed(let error):
            ContentUnavailableView(
                error.title,
                systemImage: error.systemImage,
                description: Text(error.message)
            )
        case .idle, .loaded:
            ContentUnavailableView("No posts yet", systemImage: "doc.text")
        }
    }
}
