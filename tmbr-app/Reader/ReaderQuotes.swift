import Foundation
import OSLog
import AppApi
import TmbrCore
import AppPersistence

/// Reader's lazy data-in for quotes search: fetch matching quotes (unauthenticated) and upsert
/// into the local store. `@Query` in `QuotesTab` renders the result reactively.
///
/// Unlike the blog, quotes don't have a standalone browse refresh — the browse list is
/// populated via the catalogue/blog sync. This helper only manages **search** pagination.
///
/// The search cursor is reset by each new `search(term:)` call, so `loadMore()` always
/// continues the active search.
@MainActor
final class ReaderQuotes {

    private let loader: QuotesLoader

    private let store: CatalogueStore

    private let logger = Logger(subsystem: "me.tmbr", category: "sync")

    private var currentTerm: String?

    private var nextCursor: String?

    init(loader: QuotesLoader, store: CatalogueStore) {
        self.loader = loader
        self.store = store
    }

    // MARK: - Search

    /// Fetches the first page of search results for `term` and upserts them. Resets the
    /// cursor so subsequent `loadMore()` calls continue this search.
    func search(term: String) async throws {
        currentTerm = term
        nextCursor = nil
        let page = try await fetch(term: term, cursor: nil)
        nextCursor = page.nextCursor
        try store.upsert(page.items)
        logger.info("Quotes search '\(term)': loaded \(page.items.count) quotes, nextCursor=\(page.nextCursor ?? "nil")")
    }

    // MARK: - Load more

    /// Fetches the next cursor page and upserts it. Returns `true` if more pages remain.
    func loadMore() async throws -> Bool {
        guard let term = currentTerm, let cursor = nextCursor else { return false }
        let page = try await fetch(term: term, cursor: cursor)
        nextCursor = page.nextCursor
        try store.upsert(page.items)
        logger.info("Quotes search load-more '\(term)': loaded \(page.items.count) quotes, nextCursor=\(page.nextCursor ?? "nil")")
        return page.nextCursor != nil
    }

    // MARK: - Private

    private func fetch(term: String, cursor: String?) async throws -> PageResult<QuoteResponse> {
        let query = QuotesQuery(term: term, cursor: cursor, limit: 50)
        return try await loader.load(from: query)
    }
}
