import Fluent
import Foundation

struct CreateMovieNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(MovieNote.schema)
            .field("id", .int, .identifier(auto: true))
            .field("movie_id", .int, .required)
            .field("note_id", .int, .required)
            .foreignKey("movie_id", references: Movie.schema, "id", onDelete: .cascade)
            .foreignKey("note_id", references: Note.schema, "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(MovieNote.schema).delete()
    }
}
