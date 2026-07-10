import SwiftUI

/// A list footer that owns the load-more trigger and loading spinner for a paged feed.
///
/// Self-contained: reads the nearest feed's state from `\.feedState` and fires `\.loadFeed`
/// (both scoped by `.feedControls(_:retry:)`) the moment it appears — the model guards against
/// redundant calls when `!hasMore`, no session exists yet, or a load is already in flight.
/// Renders a centered `ProgressView` while paging, and an invisible placeholder otherwise so
/// the `.onAppear` trigger stays in the list.
struct FeedLoadMoreCell: View {

    @Environment(\.feedState)
    private var state

    @Environment(\.loadFeed)
    private var loadFeed

    var body: some View {
        Group {
            if state.loading == .page {
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
            Task { await loadFeed() }
        }
    }
}
