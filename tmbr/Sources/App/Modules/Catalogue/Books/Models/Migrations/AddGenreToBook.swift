import Fluent

struct AddGenreToBook: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Book.schema)
            .field("genre", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Book.schema)
            .deleteField("genre")
            .update()
    }
}
