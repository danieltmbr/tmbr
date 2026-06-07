import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let categoryIDs: Set<Int>?

    let categorySlug: String?

    let languages: Set<String>?

    init(
        term: String? = nil,
        categoryIDs: Set<Int>? = nil,
        categorySlug: String? = nil,
        languages: Set<String>? = nil
    ) {
        self.term = term
        self.categoryIDs = categoryIDs
        self.categorySlug = categorySlug
        self.languages = languages
    }
}
