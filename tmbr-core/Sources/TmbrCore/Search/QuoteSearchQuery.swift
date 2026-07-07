import Foundation

/// Query parameters for the `GET /api/quotes?term=` paginated search path.
public struct QuoteSearchQuery: Codable, Sendable {

    public let term: String

    /// Load-more cursor — opaque value from the previous `PageResult.nextCursor`.
    public let cursor: String?

    /// Maximum items per page (server default: 50, server max: 100).
    public let limit: Int

    public init(term: String, cursor: String? = nil, limit: Int = 50) {
        self.term = term
        self.cursor = cursor
        self.limit = limit
    }
}
