import Foundation

struct QuoteQueryPayload: Decodable, Sendable {

    let term: String?

    let categoryIDs: Set<Int>?

    init(term: String? = nil, categoryIDs: Set<Int>? = nil) {
        self.term = term
        self.categoryIDs = categoryIDs
    }
}
