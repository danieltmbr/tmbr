import Fluent
import FluentSQL

struct CreateMediaResources: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("media_resources")
            .field("id", .int, .identifier(auto: true))
            .field("book_id", .int, .references("media_books", "id", onDelete: .cascade))
            .field("music_id", .int, .references("media_music", "id", onDelete: .cascade))
            .field("movie_id", .int, .references("media_movies", "id", onDelete: .cascade))
            .field("podcast_id", .int, .references("media_podcasts", "id", onDelete: .cascade))
            .field("provider", .string, .required)
            .field("external_id", .string, .required)
            .field("url", .string, .required)
            .create()

        if let sql = db as? SQLDatabase {
            try await sql.raw("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_media_resources_book_provider_unique
            ON media_resources (book_id, provider)
            WHERE book_id IS NOT NULL;
            """).run()

            try await sql.raw("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_media_resources_music_provider_unique
            ON media_resources (music_id, provider)
            WHERE music_id IS NOT NULL;
            """).run()

            try await sql.raw("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_media_resources_movie_provider_unique
            ON media_resources (movie_id, provider)
            WHERE movie_id IS NOT NULL;
            """).run()

            try await sql.raw("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_media_resources_podcast_provider_unique
            ON media_resources (podcast_id, provider)
            WHERE podcast_id IS NOT NULL;
            """).run()
        }
    }

    func revert(on db: Database) async throws {
        if let sql = db as? SQLDatabase {
            try await sql.raw("DROP INDEX IF EXISTS idx_media_resources_book_provider_unique;").run()
            try await sql.raw("DROP INDEX IF EXISTS idx_media_resources_music_provider_unique;").run()
            try await sql.raw("DROP INDEX IF EXISTS idx_media_resources_movie_provider_unique;").run()
            try await sql.raw("DROP INDEX IF EXISTS idx_media_resources_podcast_provider_unique;").run()
        }

        try await db.schema("media_resources").delete()
    }
}
