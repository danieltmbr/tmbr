import Foundation
import OSLog
import CoreApi
import CoreApp
import CoreTmbr

/// Reader's lazy data-in for the blog: fetch the public posts list (unauthenticated) and upsert
/// into the local store. `@Query` in `BlogTab` renders the result reactively.
///
/// Pagination is cursor-based: `refreshPosts()` loads the first page and stores a `nextCursor`
/// (if the server returned one); `loadMore()` continues from that cursor. `nextCursor` is reset
/// on every full refresh so pull-to-refresh always starts clean.
///
@MainActor
final class ReaderPosts {

    private let loader: PostsLoader

    private let store: PostStore

    private let logger = Logger(subsystem: "me.tmbr", category: "sync")

    private var nextCursor: String?

    init(loader: PostsLoader, store: PostStore) {
        self.loader = loader
        self.store = store
    }

    // MARK: - Refresh (first page)

    /// Fetches the first page and upserts it. Resets the cursor so subsequent `loadMore()` calls
    /// continue from the right position.
    func refreshPosts() async throws {
        let page = try await fetch(cursor: nil)
        nextCursor = page.nextCursor
        try store.upsert(page.items)
        logger.info("Blog refresh: loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
    }

    // MARK: - Load more (subsequent pages)

    /// Fetches the next cursor page and upserts it. Returns `true` if more pages remain.
    /// Returns `false` immediately (without a network call) when there is no cursor.
    func loadMore() async throws -> Bool {
        guard let cursor = nextCursor else { return false }
        let page = try await fetch(cursor: cursor)
        nextCursor = page.nextCursor
        try store.upsert(page.items)
        logger.info("Blog load-more: loaded \(page.items.count) posts, nextCursor=\(page.nextCursor ?? "nil")")
        return page.nextCursor != nil
    }

    // MARK: - Private

    private func fetch(cursor: String?) async throws -> PageResult<PostResponse> {
        let query = PageQuery(cursor: cursor, limit: 50)
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
