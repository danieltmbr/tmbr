import Foundation

/// Standard cursor-based paginated response wrapper for all API list endpoints.
///
/// - `items`: the current page of results (at most `limit` items).
/// - `hasMore`: `true` if older items remain; request with `cursor = nextCursor` to fetch them.
/// - `nextCursor`: opaque ISO 8601 date string to pass as `PageQuery.cursor` in the next request.
///   `nil` when `hasMore` is `false`.
public struct PageResult<T: Codable & Sendable>: Codable, Sendable {

    public let items: [T]

    public let hasMore: Bool

    public let nextCursor: String?

    public init(items: [T], hasMore: Bool, nextCursor: String? = nil) {
        self.items = items
        self.hasMore = hasMore
        self.nextCursor = nextCursor
    }
}
