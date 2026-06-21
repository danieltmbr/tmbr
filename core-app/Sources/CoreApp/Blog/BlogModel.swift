import Foundation
import OSLog

/// Headless model for the Blog tab. Holds refresh `phase` plus paging state — the list itself
/// comes from `@Query`.
///
/// The **per-app seam** is the pair of injected closures: Reader fetches public posts + upserts;
/// Author runs its `SyncEngine`; Personal is a no-op. `CoreApp` stays networking-free — it only
/// knows "run this async operation and track its phase / cursor state".
@MainActor
@Observable
public final class BlogModel {

    public private(set) var phase: LoadPhase = .idle

    /// `true` while a "load more" page fetch is in flight. Drives the footer spinner.
    public private(set) var isLoadingMore = false

    /// `false` once a page fetch returns no cursor, meaning there are no more pages to load.
    public private(set) var hasMore = true

    private let _refresh: @Sendable () async throws -> Void
    
    private let _loadMore: @Sendable () async throws -> Bool

    public init(
        refresh: @escaping @Sendable () async throws -> Void = {},
        loadMore: @escaping @Sendable () async throws -> Bool = { false }
    ) {
        self._refresh = refresh
        self._loadMore = loadMore
    }

    // MARK: - Refresh (first page)

    public func refresh() async {
        phase = .loading
        do {
            try await _refresh()
            phase = .loaded
            hasMore = true  // optimistic — first loadMore() will settle it
        } catch {
            Logger.blog.error("Blog refresh failed: \(error)")
            phase = .failed(LoadError(error))
        }
    }

    // MARK: - Load more (subsequent pages)

    /// Fetches the next page if one is available. Never flips `phase` to `.failed` — a paging
    /// hiccup on a populated list shouldn't blank the screen.
    public func loadMore() async {
        guard hasMore, !isLoadingMore, phase != .loading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            hasMore = try await _loadMore()
        } catch {
            Logger.blog.error("Blog load-more failed: \(error)")
        }
    }
}
