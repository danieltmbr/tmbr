import Fluent

struct CreateMediaResource: AsyncMigration {
    func prepare(on database: Database) async throws {
        // A single table stores resources for all item types; only one of the *_id columns should be set.
        try await database.schema("media_resources")
            .field("id", .int, .identifier(auto: true))
            .field("book_id", .int, .references("media_books", "id", onDelete: .cascade))
            .field("music_id", .int, .references("media_music", "id", onDelete: .cascade))
            .field("movie_id", .int, .references("media_movies", "id", onDelete: .cascade))
            .field("podcast_id", .int, .references("media_podcasts", "id", onDelete: .cascade))
            .field("platform", .string, .required)
            .field("external_id", .string, .required)
            .field("url", .string, .required)
            .unique(on: "book_id", "platform", "external_id")
            .unique(on: "music_id", "platform", "external_id")
            .unique(on: "movie_id", "platform", "external_id")
            .unique(on: "podcast_id", "platform", "external_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media_resources").delete()
    }
}
