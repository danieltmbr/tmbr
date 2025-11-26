import Fluent

struct CreateMediaItems: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Book
        try await database.schema("media_books")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .create()
        
        // Music (with optional entity enum)
        let musicEntity = try await database.enum("media_music_entity")
            .case("song")
            .case("playlist")
            .case("album")
            .create()
        
        try await database.schema("media_music")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .field("entity", musicEntity)
            .create()
        
        // Movie
        try await database.schema("media_movies")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .create()
        
        // Podcast
        try await database.schema("media_podcasts")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media_podcasts").delete()
        try await database.schema("media_movies").delete()
        try await database.schema("media_music").delete()
        try await database.enum("media_music_entity").delete()
        try await database.schema("media_books").delete()
    }
}
