import Foundation
import TmbrCore
import ApiKit

/// Drives a paginated endpoint to completion.
///
/// Delta sync sends `since` on the **first** page only, then follows `nextCursor` (older pages) until
/// the server returns `nil`. The query type is generic via `makeQuery`, so the same driver handles
/// `PageQuery` and richer queries (e.g. orphans' `?notes=true`).
public enum PageLoader {

    public static func fetchAll<Q: Encodable & Sendable, T: Decodable & Sendable>(
        loader: RequestLoader<BasicRequest<Q, PageResult<T>>>,
        since: Date?,
        makeQuery: @Sendable (_ since: Date?, _ cursor: String?) -> Q
    ) async throws -> [T] {
        var all: [T] = []
        var cursor: String?
        repeat {
            let query = makeQuery(all.isEmpty ? since : nil, cursor)
            let page = try await loader.load(from: query)
            all.append(contentsOf: page.items)
            cursor = page.nextCursor
        } while cursor != nil
        return all
    }

    /// Convenience for the standard `PageQuery` endpoints (per-type lists, posts).
    public static func fetchAll<T: Decodable & Sendable>(
        loader: RequestLoader<BasicRequest<PageQuery, PageResult<T>>>,
        since: Date?,
        limit: Int = 50
    ) async throws -> [T] {
        try await fetchAll(loader: loader, since: since) { since, cursor in
            PageQuery(since: since, cursor: cursor, limit: limit)
        }
    }
}
