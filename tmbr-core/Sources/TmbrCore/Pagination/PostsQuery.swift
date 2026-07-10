import Foundation

/// Query parameters for `GET /api/posts` — supports both paginated browse and text search.
///
/// The server accepts `term`, `since`, `cursor`, `limit`, and `languages` in any combination.
/// Pass `term` to filter results by text; omit it for a plain paginated list.
public struct PostsQuery: Codable, Hashable, Sendable {

    /// Load-more cursor — opaque value from the previous `PageResult.nextCursor`.
    public let cursor: String?

    /// Language codes to filter by. `nil` means the server's language preference applies.
    public let languages: [String]?
    
    /// Maximum items per page (server default: 50, server max: 100).
    public let limit: Int
    
    /// Delta-sync cursor — returns items created after this date.
    public let since: Date?
    
    /// Optional full-text filter. `nil` means browse all posts.
    public let term: String?

    public init(
        cursor: String? = nil,
        languages: [String]? = nil,
        limit: Int = 50,
        since: Date? = nil,
        term: String? = nil
    ) {
        self.term = term
        self.since = since
        self.cursor = cursor
        self.limit = limit
        self.languages = languages
    }
    
    public init(
        cursor: String? = nil,
        languages: Set<Language>? = nil,
        limit: Int = 50,
        since: Date? = nil,
        term: String
    ) {
        self.init(
            cursor: cursor,
            languages: languages?.map { $0.rawValue },
            limit: limit,
            since: since,
            term: term.isEmpty ? nil : term
        )
    }

    /// The same query pointed at the next page — `cursor` replaced, everything else preserved.
    public func page(after cursor: String) -> Self {
        PostsQuery(
            cursor: cursor,
            languages: languages,
            limit: limit,
            since: since,
            term: term
        )
    }
}
