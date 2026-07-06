import Foundation

/// Query parameters for the `GET /api/catalogue/quotes/search` endpoint.
///
/// `types` is an optional list of category slugs for source filtering. Pass `nil` to search
/// across all quote sources. Blog-post-sourced quotes are handled by local filtering only
/// (the server has no `__blog_posts__` sentinel concept).
public struct QuoteSearchQuery: Codable, Sendable {

    public let term: String

    public let types: [String]?

    public init(term: String, types: [String]? = nil) {
        self.term = term
        self.types = types
    }
}
