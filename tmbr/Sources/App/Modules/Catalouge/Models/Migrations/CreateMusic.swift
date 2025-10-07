import Fluent

struct CreateMusic: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("media_music")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .field("nature", .string)
            .unique(on: "media_id")
            .create()
    }

    func revert(on db: Database) async throws {
        try await db.schema("media_music").delete()
    }
}
