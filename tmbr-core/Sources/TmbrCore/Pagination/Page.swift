import Foundation

/// Standard cursor-based paginated response wrapper for all API list endpoints.
///
/// - `items`: the current page of results (at most `limit` items).
/// - `nextCursor`: opaque ISO 8601 date string to pass as `PageQuery.cursor` in the next request.
///   `nil` when no older items remain.
public struct PageResult<T: Codable & Sendable>: Codable, Sendable {

    public let items: [T]

    public let nextCursor: String?

    public init(items: [T], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
