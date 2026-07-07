import Foundation
import OSLog
import AppApi
import TmbrCore
import AppPersistence

/// Reader's lazy data-in for catalogue search: fetch matching items and notes (unauthenticated)
/// and upsert them into the local store. `CatalogueSearchEngine` in `CatalogueTab` then re-runs
/// the local search to pick up the new records.
///
/// `search(term:)` resets the cursor so `loadMore()` always continues the active search.
@MainActor
final class ReaderCatalogue {

    private let loader: CatalogueSearchLoader

    private let store: CatalogueStore

    private let logger = Logger(subsystem: "me.tmbr", category: "sync")

    private var currentTerm: String?

    private var nextCursor: String?

    init(loader: CatalogueSearchLoader, store: CatalogueStore) {
        self.loader = loader
        self.store = store
    }

    // MARK: - Search

    /// Fetches the first page of search results for `term` and upserts them. Resets the cursor
    /// so subsequent `loadMore()` calls continue this search.
    func search(term: String) async throws {
        currentTerm = term
        nextCursor = nil
        let response = try await fetch(term: term, cursor: nil)
        nextCursor = response.nextCursor
        try store.upsertSearch(response)
        logger.info("Catalogue search '\(term)': \(response.items.count) items, \(response.notes.count) notes, nextCursor=\(response.nextCursor ?? "nil")")
    }

    // MARK: - Load more

    /// Fetches the next cursor page and upserts it. Returns `true` if more pages remain.
    func loadMore() async throws -> Bool {
        guard let term = currentTerm, let cursor = nextCursor else { return false }
        let response = try await fetch(term: term, cursor: cursor)
        nextCursor = response.nextCursor
        try store.upsertSearch(response)
        logger.info("Catalogue load-more '\(term)': \(response.items.count) items, \(response.notes.count) notes, nextCursor=\(response.nextCursor ?? "nil")")
        return response.nextCursor != nil
    }

    // MARK: - Private

    private func fetch(term: String, cursor: String?) async throws -> CatalogueSearchResponse {
        let query = CatalogueSearchQuery(term: term, cursor: cursor, limit: 20)
        return try await loader.load(from: query)
    }
}
