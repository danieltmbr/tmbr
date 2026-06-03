import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let types: Set<String>?

    let categories: Set<String>?

    init(term: String? = nil, types: Set<String>? = nil, categories: Set<String>? = nil) {
        self.term = term
        self.types = types
        self.categories = categories
    }
}
