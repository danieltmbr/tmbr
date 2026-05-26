import Fluent

struct AddSourceURLToImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("gallery")
            .field("source_url", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("gallery")
            .deleteField("source_url")
            .update()
    }
}
