import SwiftUI

/// A list footer that owns the load-more trigger and loading spinner.
///
/// Fires `loadBlog` the moment it appears (the model guards against redundant calls when
/// `!hasMore` or `isLoadingMore`). Renders a centered `ProgressView` while loading, and an
/// invisible placeholder otherwise so the `.onAppear` trigger stays in the list.
struct BlogLoadMoreCell: View {

    @Blog(\.isLoadingMore)
    private var isLoadingMore

    @Blog(\.hasMore)
    private var hasMore

    @Environment(\.loadBlog)
    private var loadBlog

    var body: some View {
        Group {
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .listRowSeparator(.hidden)
        .onAppear {
            Task { await loadBlog() }
        }
    }
}
