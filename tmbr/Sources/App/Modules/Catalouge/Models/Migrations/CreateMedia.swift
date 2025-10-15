import Fluent
import SQLKit

struct CreateMedia: AsyncMigration {
    func prepare(on database: Database) async throws {
        // enums
        let collaboration = try await database.enum("media_collaboration")
            .case("none")
            .case("authors")
            .case("users")
            .create()
        
        let kind = try await database.enum("media_kind")
            .case("music")
            .case("movie")
            .case("book")
            .case("podcast")
            .create()
        
        // table
        try await database.schema("media")
            .field("id", .int, .identifier(auto: true))
            .field("owner_id", .int, .required, .references("users", "id", onDelete: .cascade))
            .field("kind", kind, .required)
            .field("preview_title", .string, .required)
            .field("preview_subtitle", .string)
            .field("preview_body", .string)
            .field("preview_image_url", .string)
            .field("collaboration", collaboration, .required, .sql(.default("none")))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media").delete()
        try await database.enum("media_kind").delete()
        try await database.enum("media_collaboration").delete()
    }
}
