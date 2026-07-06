import Foundation

/// Query parameters for the `GET /api/posts?term=` search path.
public struct PostSearchQuery: Codable, Sendable {

    public let term: String

    public init(term: String) {
        self.term = term
    }
}
