import Foundation

/// Which load operation is currently in flight, if any.
public enum LoadingState: Equatable, Sendable {
    case refresh
    case page
}

/// Observable UI state of one feed — everything feed components render from.
///
/// Non-generic on purpose: components like `FeedStatusLine` and `FeedLoadMoreCell` read it via
/// `\.feedState` without caring which feed (or `Input` type) they serve. The owning list scopes
/// it — together with the control actions — via `.feedControls(_:retry:)`. `FeedModel` is the
/// only writer.
///
/// Reads are tracked per property by Observation: a view reading only `loading` re-renders only
/// when `loading` changes.
@MainActor
@Observable
public final class FeedState {

    /// Which load operation is currently in flight; `nil` when idle.
    public internal(set) var loading: LoadingState?

    /// Whether the active session is a search (`search(_:)` was the last page-1 request)
    /// rather than browse. Drives search-specific presentation, e.g. `FeedEmptyView`'s
    /// "no results" state.
    public internal(set) var isSearching = false

    /// `false` once a fetch returns no cursor, meaning there are no more pages to load.
    public internal(set) var hasMore = true

    /// The error from the last refresh/search attempt; `nil` after a success.
    public internal(set) var lastError: LoadError?

    /// When the last successful refresh completed. Seeded from persisted storage by `@Feed`.
    public internal(set) var lastFetched: Date?

    /// Increments after every successful fetch+upsert. Views that read the store manually
    /// (e.g. `CatalogueSearchEngine`) observe this to re-run their local query.
    public internal(set) var revision = 0

    nonisolated public init() {}
}
