import Fluent

struct CreateImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Image.schema)
            .field("id", .int, .identifier(auto: true))
            .field("alt", .string)
            .field("path", .string, .required)
            .field("thumbnail_path", .string, .required)
            .field("size_width", .int, .required)
            .field("size_height", .int, .required)
            .field("uploaded_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Image.schema).delete()
    }
}
