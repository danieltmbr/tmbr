import Foundation
import OSLog

/// Which load operation is currently in flight, if any.
public enum LoadingState: Equatable, Sendable {
    case refreshing
    case pageLoad
}

/// Headless model for the Blog tab. Tracks refresh activity and outcome; the list itself comes
/// from `@Query` in the view.
///
/// The **per-app seam** is the pair of injected closures: Reader fetches public posts + upserts;
/// Author runs its `SyncEngine`; Personal is a no-op. `CoreApp` stays networking-free — it only
/// knows "run this async operation and track its state."
///
/// `_refresh` returns the date when data was successfully fetched — or `nil` if not applicable
/// (Personal, no-op). Persistence of that date across launches is the caller's responsibility.
@MainActor
@Observable
public final class BlogModel {

    // MARK: - Public state

    /// Which load operation is currently in flight; `nil` when idle.
    public private(set) var activeLoad: LoadingState?

    /// Convenience for the footer spinner.
    public var isPageLoading: Bool { activeLoad == .pageLoad }

    /// `false` once a page fetch returns no cursor, meaning there are no more pages to load.
    public private(set) var hasMore = true

    /// The error from the last refresh attempt; `nil` after a successful refresh.
    public private(set) var lastError: LoadError?

    /// When the last successful refresh completed. Set from the value returned by `_refresh`.
    /// Persisting this across launches is the caller's responsibility.
    public private(set) var lastFetched: Date?

    // MARK: - Dependencies

    private let _refresh: @Sendable () async throws -> Date?
    private let _loadMore: @Sendable () async throws -> Bool

    public init(
        refresh: @escaping @Sendable () async throws -> Date? = { nil },
        loadMore: @escaping @Sendable () async throws -> Bool = { false },
        lastFetched: Date? = nil
    ) {
        self._refresh = refresh
        self._loadMore = loadMore
        self.lastFetched = lastFetched
    }

    // MARK: - Refresh (first page)

    public func refresh() async {
        guard activeLoad == nil else { return }
        activeLoad = .refreshing
        defer { activeLoad = nil }
        do {
            if let date = try await _refresh() {
                lastFetched = date
            }
            lastError = nil
            hasMore = true  // optimistic — first loadMore() will settle it
        } catch {
            Logger.blog.error("Blog refresh failed: \(error)")
            lastError = LoadError(error)
        }
    }

    // MARK: - Load more (subsequent pages)

    /// Fetches the next page if one is available. Never surfaces its error to the UI —
    /// a paging hiccup on a populated list shouldn't blank the screen.
    public func loadMore() async {
        guard hasMore, activeLoad == nil else { return }
        activeLoad = .pageLoad
        defer { activeLoad = nil }
        do {
            hasMore = try await _loadMore()
        } catch {
            Logger.blog.error("Blog load-more failed: \(error)")
        }
    }
}
