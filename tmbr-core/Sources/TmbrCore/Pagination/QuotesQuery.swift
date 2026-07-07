import Foundation

/// Query parameters for `GET /api/catalogue/quotes` — supports both paginated browse and text search.
///
/// Pass `term` to filter results by text; omit it for a plain paginated list.
public struct QuotesQuery: Codable, Sendable {

    /// Optional full-text filter. `nil` means browse all quotes.
    public let term: String?

    /// Load-more cursor — opaque value from the previous `PageResult.nextCursor`.
    public let cursor: String?

    /// Maximum items per page (server default: 50, server max: 100).
    public let limit: Int

    public init(
        term: String? = nil,
        cursor: String? = nil,
        limit: Int = 50
    ) {
        self.term = term
        self.cursor = cursor
        self.limit = limit
    }
}
