import SwiftUI

public extension EnvironmentValues {

    /// App-wide persisted-defaults store — injectable for tests/previews.
    @Entry var userDefaults: UserDefaults = .standard

    /// The nearest feed's observable UI state. Inert default; scoped by `.feedControls(_:retry:)`.
    @Entry var feedState: FeedState = FeedState()

    /// Loads the next page of the nearest feed's session.
    @Entry var loadFeed: FeedPageLoadAction = FeedPageLoadAction()

    /// Re-fires page 1 of the nearest feed's session.
    @Entry var retryFeed: FeedRetryAction = FeedRetryAction()
}

public extension View {

    /// Scopes a feed's observable state and control actions for descendant feed components
    /// (`FeedStatusLine`, `FeedLoadMoreCell`, `FeedEmptyView`) — they read `\.feedState`,
    /// `\.loadFeed`, and `\.retryFeed` instead of receiving a model through their initializers.
    ///
    /// `.feed(_:)` already applies this; call it directly only to re-scope a specific feed
    /// where several coexist in one subtree (e.g. the catalogue's search load-more cell).
    func feedControls<Input>(_ feed: FeedModel<Input>) -> some View where Input: PageableQuery {
        environment(\.feedState, feed.state)
            .environment(\.loadFeed, FeedPageLoadAction { await feed.loadMore() })
            .environment(\.retryFeed, FeedRetryAction { await feed.retry() })
    }
}
