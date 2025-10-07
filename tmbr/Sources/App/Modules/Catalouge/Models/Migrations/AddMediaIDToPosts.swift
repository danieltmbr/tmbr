import Fluent
import Foundation

struct AddMediaIDToPosts: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("posts")
            .field("media_id", .int)
            .update()
        try await db.schema("posts")
            .foreignKey("media_id", references: "media", "id", onDelete: .setNull, onUpdate: .cascade)
            .update()
    }

    func revert(on db: Database) async throws {
        try await db.schema("posts")
            .deleteField("media_id")
            .update()
    }
}
