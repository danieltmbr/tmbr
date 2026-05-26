import Fluent

struct AddMissingFieldsToPodcast: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Podcast.schema)
            .field("episode_number", .int)
            .field("episode_title", .string, .required, .sql(.default("")))
            .field("genre", .string)
            .field("season", .int)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Podcast.schema)
            .deleteField("episode_number")
            .deleteField("episode_title")
            .deleteField("genre")
            .deleteField("season")
            .update()
    }
}
