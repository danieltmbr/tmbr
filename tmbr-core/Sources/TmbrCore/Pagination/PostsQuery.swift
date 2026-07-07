import Foundation

/// Query parameters for `GET /api/posts` — supports both paginated browse and text search.
///
/// The server accepts `term`, `since`, `cursor`, and `limit` in any combination.
/// Pass `term` to filter results by text; omit it for a plain paginated list.
public struct PostsQuery: Codable, Sendable {

    /// Optional full-text filter. `nil` means browse all posts.
    public let term: String?

    /// Delta-sync cursor — returns items created after this date.
    public let since: Date?

    /// Load-more cursor — opaque value from the previous `PageResult.nextCursor`.
    public let cursor: String?

    /// Maximum items per page (server default: 50, server max: 100).
    public let limit: Int

    public init(
        term: String? = nil,
        since: Date? = nil,
        cursor: String? = nil,
        limit: Int = 50
    ) {
        self.term = term
        self.since = since
        self.cursor = cursor
        self.limit = limit
    }
}
