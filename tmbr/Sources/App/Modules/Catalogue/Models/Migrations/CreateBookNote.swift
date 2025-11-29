import Fluent
import Foundation

struct CreateBookNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(BookNote.schema)
            .field("id", .int, .identifier(auto: true))
            .field("book_id", .int, .required)
            .field("note_id", .int, .required)
            .foreignKey("book_id", references: Book.schema, "id", onDelete: .cascade)
            .foreignKey("note_id", references: Note.schema, "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(BookNote.schema).delete()
    }
}
