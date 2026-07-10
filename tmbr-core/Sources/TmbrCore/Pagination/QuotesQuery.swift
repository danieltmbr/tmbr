import Foundation

/// Query parameters for `GET /api/catalogue/quotes` — supports both paginated browse and text search.
///
/// Pass `term` to filter results by text; omit it for a plain paginated list.
public struct QuotesQuery: Codable, Hashable, Sendable {

    /// Load-more cursor — opaque value from the previous `PageResult.nextCursor`.
    public let cursor: String?

    /// Language codes to filter by. `nil` means the server's language preference applies.
    public let languages: [String]?

    /// Maximum items per page (server default: 50, server max: 100).
    public let limit: Int

    /// Source buckets to filter by: catalogue category slugs plus the `blog_posts` sentinel.
    /// `nil` means all sources.
    public let sources: [String]?

    /// Optional full-text filter. `nil` means browse all quotes.
    public let term: String?

    public init(
        cursor: String? = nil,
        languages: [String]? = nil,
        limit: Int = 50,
        sources: [String]? = nil,
        term: String? = nil
    ) {
        self.cursor = cursor
        self.languages = languages
        self.limit = limit
        self.sources = sources
        self.term = term
    }

    public init(
        cursor: String? = nil,
        languages: Set<Language>? = nil,
        limit: Int = 50,
        sources: [String]? = nil,
        term: String
    ) {
        self.init(
            cursor: cursor,
            languages: languages?.map { $0.rawValue },
            limit: limit,
            sources: sources,
            term: term.isEmpty ? nil : term
        )
    }

    /// The same query pointed at the next page — `cursor` replaced, everything else preserved.
    public func page(after cursor: String) -> Self {
        QuotesQuery(
            cursor: cursor,
            languages: languages,
            limit: limit,
            sources: sources,
            term: term
        )
    }
}
