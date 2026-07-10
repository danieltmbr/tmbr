import SwiftUI

/// Overlay shown when a feed-backed list is empty, switching on the current load state:
/// a spinner while fetching, the typed error with a retry button after a failure, the standard
/// "no results" while a search session is active — browse and search alike — and the caller's
/// own idle-empty content otherwise (the feature's "nothing here yet").
///
/// Self-contained: reads the nearest feed's state from `\.feedState` and fires `\.retryFeed`
/// (both scoped by `.feed(_:)` / `.feedControls(_:)`).
struct FeedEmptyView<EmptyContent: View>: View {

    @Environment(\.feedState)
    private var state

    @Environment(\.retryFeed)
    private var retryFeed

    @ViewBuilder
    let emptyContent: () -> EmptyContent

    var body: some View {
        if state.loading == .refresh {
            ProgressView()
        } else if let error = state.lastError {
            ContentUnavailableView {
                Label(error.title, systemImage: error.systemImage)
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") { Task { await retryFeed() } }
            }
        } else if state.isSearching {
            ContentUnavailableView.search
        } else {
            emptyContent()
        }
    }
}
