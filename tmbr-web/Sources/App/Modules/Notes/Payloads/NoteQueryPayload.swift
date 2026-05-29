import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let categoryIDs: Set<UUID>?

    let languages: Set<String>?

    init(term: String? = nil, categoryIDs: Set<UUID>? = nil, languages: Set<String>? = nil) {
        self.term = term
        self.categoryIDs = categoryIDs
        self.languages = languages
    }
}
