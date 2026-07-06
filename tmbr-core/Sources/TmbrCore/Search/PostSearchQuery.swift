import Foundation

/// Query parameters for the `GET /api/posts/search` endpoint.
public struct PostSearchQuery: Codable, Sendable {

    /// Search term — matched against post title and body content.
    public let term: String

    public init(term: String) {
        self.term = term
    }
}
