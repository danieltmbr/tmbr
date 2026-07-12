import Foundation
import OSLog
import AppPersistence

/// Headless model for the Quotes tab — tracks the active source filter and wires the
/// per-app search seam.
///
/// `selectedSources` is a unified set of **source buckets**: catalogue category slugs
/// (for note-sourced quotes) plus `.blogPosts` (for post-sourced quotes).
/// Empty = no filter (show all).
///
/// This is intentionally decoupled from `CatalogueModel` — the Quotes filter is a
/// superset of catalogue categories (it also spans blog posts), so the two tabs maintain
/// independent selections.
@MainActor
@Observable
public final class QuotesModel {

    // MARK: - Public state

    /// Source buckets currently active in the filter. Empty = no filter (show all).
    public var selectedSources: Set<QuoteSourceFilter> = []

    /// Non-nil while a search network request is in flight.
    public private(set) var isSearching = false

    /// `false` once a search load-more returns no cursor, meaning no more search pages.
    public private(set) var hasMore = true

    /// Non-nil while a load-more network request is in flight.
    public private(set) var isLoadingMore = false

    // MARK: - Dependencies

    /// Per-app seam for quotes search. Called with the current search term; should fetch
    /// matching quotes from the server and upsert them into the local store.
    private let _search: @Sendable (String) async throws -> Void

    /// Per-app seam for loading the next page of search results.
    private let _loadMore: @Sendable () async throws -> Bool

    public init(
        search: @escaping @Sendable (String) async throws -> Void = { _ in },
        loadMore: @escaping @Sendable () async throws -> Bool = { false }
    ) {
        self._search = search
        self._loadMore = loadMore
    }

    // MARK: - Search

    /// Fires the injected search closure with `term`. Resets `hasMore` optimistically.
    public func search(term: String) async {
        guard !isSearching else { return }
        isSearching = true
        hasMore = true  // reset — load-more will settle it after the first search page
        defer { isSearching = false }
        do {
            try await _search(term)
        } catch {
            Logger.quotes.error("Quotes search failed: \(error)")
            hasMore = false
        }
    }

    // MARK: - Load more (subsequent search pages)

    public func loadMore() async {
        guard hasMore, !isLoadingMore, !isSearching else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            hasMore = try await _loadMore()
        } catch {
            Logger.quotes.error("Quotes load-more failed: \(error)")
        }
    }
}
