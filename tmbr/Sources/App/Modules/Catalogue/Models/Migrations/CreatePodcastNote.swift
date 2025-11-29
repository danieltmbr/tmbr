import Fluent
import Foundation

struct CreatePodcastNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PodcastNote.schema)
            .field("id", .int, .identifier(auto: true))
            .field("note_id", .int, .required)
            .field("podcast_id", .int, .required)
            .foreignKey("note_id", references: Note.schema, "id", onDelete: .cascade)
            .foreignKey("podcast_id", references: Podcast.schema, "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(PodcastNote.schema).delete()
    }
}
