import Fluent
import Foundation
import FluentSQL

struct CreateMediaNotes: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("media_notes")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("text", .sql(.text), .required)
            .field("commentary", .sql(.text))
            .field("position_start", .string)
            .field("position_end", .string)
            .field("state", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on db: Database) async throws {
        try await db.schema("media_notes").delete()
    }
}
