import Foundation

/// Query parameters for the `GET /api/catalogue/search` endpoint.
///
/// `types` is an optional list of category slugs (e.g. `["song", "book"]`). Pass `nil` to search
/// across all catalogue types. The server's mapper converts slugs to category IDs internally.
///
/// `cursor` is an ISO 8601 date string returned as `nextCursor` from a previous response;
/// the server treats it as "return only items created before this date".
public struct CatalogueSearchQuery: Codable, Hashable, Sendable {

    public let term: String

    public let types: [String]?

    public let languages: [String]?

    /// Opaque pagination cursor — an ISO 8601 date string from a previous `CatalogueSearchResponse.nextCursor`.
    public let cursor: String?

    public let limit: Int

    public init(
        term: String,
        types: [String]? = nil,
        languages: [String]? = nil,
        cursor: String? = nil,
        limit: Int = 20
    ) {
        self.term = term
        self.types = types
        self.languages = languages
        self.cursor = cursor
        self.limit = limit
    }

    /// The same query pointed at the next page — `cursor` replaced, everything else preserved.
    public func page(after cursor: String) -> Self {
        CatalogueSearchQuery(term: term, types: types, languages: languages, cursor: cursor, limit: limit)
    }
}
