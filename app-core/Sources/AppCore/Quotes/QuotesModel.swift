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

    // MARK: - Dependencies

    /// Per-app seam for quotes search. Called with the current search term; should fetch
    /// matching quotes from the server and upsert them into the local store.
    private let _search: @Sendable (String) async throws -> Void

    public init(search: @escaping @Sendable (String) async throws -> Void = { _ in }) {
        self._search = search
    }

    // MARK: - Search

    public func search(term: String) async {
        guard !isSearching else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            try await _search(term)
        } catch {
            Logger.quotes.error("Quotes search failed: \(error)")
        }
    }
}
