import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let types: Set<String>?

    let languages: Set<String>?

    init(term: String? = nil, types: Set<String>? = nil, languages: Set<String>? = nil) {
        self.term = term
        self.types = types
        self.languages = languages
    }
}
