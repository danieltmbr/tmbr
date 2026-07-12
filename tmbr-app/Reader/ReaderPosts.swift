import Foundation
import OSLog
import AppApi
import AppCore
import TmbrCore
import AppPersistence

/// Reader's lazy data-in for the blog: fetch posts (unauthenticated) and upsert into the local
/// store. `@Query` in `BlogTab` renders the result reactively.
///
/// The loader hits a single unified endpoint (`GET /api/posts`) that accepts both pagination
/// cursors and an optional search `term`. Browse and search share the same fetch path; the
/// caller supplies the term.
///
/// **Cursor strategy** — two independent cursors are kept so browse and search pagination
/// are independent: clearing a search returns to the browse page where the user left off.
///
/// - `browseCursor` — tracks the next browse page; reset by `refreshPosts()`.
/// - `searchCursor` — tracks the next search page; reset by each new `search(term:)` call.
/// - `currentTerm` — nil means browse mode; non-nil means search mode.
@MainActor
final class ReaderPosts {

    private let loader: PostsLoader

    private let store: PostStore

    private let logger = Logger(subsystem: "me.tmbr", category: "sync")

    private var browseCursor: String?

    private var searchCursor: String?

    private var currentTerm: String?

    init(loader: PostsLoader, store: PostStore) {
        self.loader = loader
        self.store = store
    }

    // MARK: - Browse

    /// Fetches the first browse page and upserts it. Resets the browse cursor and clears any
    /// active search term so subsequent `loadMore()` calls continue the browse list.
    func refreshPosts() async throws {
        let page = try await fetch(term: nil, cursor: nil)
        browseCursor = page.nextCursor
        currentTerm = nil
        searchCursor = nil
        try store.upsert(page.items)
        logger.info("Blog refresh: loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
    }

    // MARK: - Search

    /// Fetches the first page of search results for `term` and upserts them. Resets the search
    /// cursor so subsequent `loadMore()` calls continue the search, not the browse list.
    func search(term: String) async throws {
        currentTerm = term
        searchCursor = nil
        let page = try await fetch(term: term, cursor: nil)
        searchCursor = page.nextCursor
        try store.upsert(page.items)
        logger.info("Blog search '\(term)': loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
    }

    // MARK: - Load more

    /// Fetches the next cursor page (browse or search, depending on `currentTerm`) and upserts
    /// it. Returns `true` if more pages remain.
    func loadMore() async throws -> Bool {
        if let term = currentTerm {
            guard let cursor = searchCursor else { return false }
            let page = try await fetch(term: term, cursor: cursor)
            searchCursor = page.nextCursor
            try store.upsert(page.items)
            logger.info("Blog search load-more '\(term)': loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
            return page.nextCursor != nil
        } else {
            guard let cursor = browseCursor else { return false }
            let page = try await fetch(term: nil, cursor: cursor)
            browseCursor = page.nextCursor
            try store.upsert(page.items)
            logger.info("Blog load-more: loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
            return page.nextCursor != nil
        }
    }

    // MARK: - Private

    private func fetch(term: String?, cursor: String?) async throws -> PageResult<PostResponse> {
        let query = PostsQuery(term: term, cursor: cursor, limit: 50)
        do {
            return try await loader.load(from: query)
        } catch let error as RequestError {
            logger.error("Blog fetch failed with HTTP error: \(error)")
            throw LoadError.server(status: {
                if case .httpError(let status, _) = error { return status }
                return nil
            }())
        }
    }
}
