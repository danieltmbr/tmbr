import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let categoryIDs: Set<UUID>?

    init(term: String? = nil, categoryIDs: Set<UUID>? = nil) {
        self.term = term
        self.categoryIDs = categoryIDs
    }
}
