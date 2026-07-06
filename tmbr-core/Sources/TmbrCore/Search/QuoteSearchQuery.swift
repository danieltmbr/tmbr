import Foundation

/// Query parameters for the `GET /api/catalogue/quotes?term=` search path.
public struct QuoteSearchQuery: Codable, Sendable {

    public let term: String

    public init(term: String) {
        self.term = term
    }
}
