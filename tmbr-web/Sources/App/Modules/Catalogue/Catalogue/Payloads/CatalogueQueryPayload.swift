import Foundation

struct CatalogueQueryPayload: Decodable, Sendable {

    let term: String?

    let types: Set<String>?

    let languages: Set<String>?

    /// Opaque cursor string from a previous `CatalogueSearchResponse.nextCursor` — used by the
    /// search endpoint to return the next page of results. Ignored by non-search endpoints.
    let cursor: String?

    /// Maximum results to return from the search endpoint. Ignored by non-search endpoints.
    let limit: Int?

    init(
        term: String? = nil,
        types: Set<String>? = nil,
        languages: Set<String>? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) {
        self.term = term
        self.types = types
        self.languages = languages
        self.cursor = cursor
        self.limit = limit
    }
}

