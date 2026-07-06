import Foundation

/// Query parameters for the `GET /api/catalogue/search` endpoint.
///
/// `types` is an optional list of category slugs (e.g. `["song", "book"]`). Pass `nil` to search
/// across all catalogue types. The server's mapper converts slugs to category IDs internally.
public struct CatalogueSearchQuery: Codable, Sendable {

    public let term: String

    public let types: [String]?

    public let languages: [String]?

    public init(term: String, types: [String]? = nil, languages: [String]? = nil) {
        self.term = term
        self.types = types
        self.languages = languages
    }
}
