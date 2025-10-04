import Fluent

struct CreatePost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("posts")
            .field("id", .int, .identifier(auto: true))
            .field("title", .string, .required)
            .field("content", .string, .required)
            .field("created_at", .datetime)
            .field("state", .string, .required)
            .field("author_id", .int, .required, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("posts").delete()
    }
}
