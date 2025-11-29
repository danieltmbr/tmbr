import Fluent
import Foundation

struct CreateSongNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(SongNote.schema)
            .field("id", .int, .identifier(auto: true))
            .field("note_id", .int, .required)
            .field("song_id", .int, .required)
            .foreignKey("note_id", references: Note.schema, "id", onDelete: .cascade)
            .foreignKey("song_id", references: Song.schema, "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(SongNote.schema).delete()
    }
}
