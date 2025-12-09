import Fluent
import Vapor
import Foundation

final class BookNote: Model, @unchecked Sendable {
    static let schema = "book_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "book_id")
    private(set) var book: Book

    @Parent(key: "note_id")
    private(set) var note: Note
    
    init() {}
    
    init(book: BookID, note: NoteID) {
        self.$book.id = book
        self.$note.id = note
    }
}
