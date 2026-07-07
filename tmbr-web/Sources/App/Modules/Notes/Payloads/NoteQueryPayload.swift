import Foundation

struct NoteQueryPayload: Decodable, Sendable {

    let term: String?

    let categoryIDs: Set<Int>?

    let categorySlug: String?

    let languages: Set<String>?

    /// "Return only notes created before this date" — used for cursor-based pagination.
    let before: Date?

    /// Maximum number of notes to return; `nil` means no limit.
    let limit: Int?

    init(
        term: String? = nil,
        categoryIDs: Set<Int>? = nil,
        categorySlug: String? = nil,
        languages: Set<String>? = nil,
        before: Date? = nil,
        limit: Int? = nil
    ) {
        self.term = term
        self.categoryIDs = categoryIDs
        self.categorySlug = categorySlug
        self.languages = languages
        self.before = before
        self.limit = limit
    }
}
