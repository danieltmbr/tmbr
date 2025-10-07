import Fluent
import Foundation

struct CreateMedia: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("media")
            .field("id", .int, .identifier(auto: true))
            .field("kind", .string, .required)
            .field("preview_title", .string, .required)
            .field("preview_subtitle", .string)
            .field("preview_body", .string)
            .field("preview_image_url", .string)
            .create()
    }

    func revert(on db: Database) async throws {
        try await db.schema("media").delete()
    }
}
