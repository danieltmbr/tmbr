import Fluent

struct CreateBooks: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("media_books")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .unique(on: "media_id")
            .create()
    }

    func revert(on db: Database) async throws {
        try await db.schema("media_books").delete()
    }
}
