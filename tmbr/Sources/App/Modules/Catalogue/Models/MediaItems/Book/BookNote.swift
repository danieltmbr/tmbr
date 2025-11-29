import Fluent
import Vapor
import Foundation

final class BookNote: Model, @unchecked Sendable {
    static let schema = "book_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "book_id")
    var book: Book

    @Parent(key: "note_id")
    var note: Note
}
