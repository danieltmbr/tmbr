import Fluent
import Foundation
import SQLKit

/// Replaces the original `quotes` table with a new schema that:
///   - Uses a user-generated UUID primary key (stable identity across source edits)
///   - Supports polymorphic sources: optional `note_id` OR optional `post_id`
///
/// Quotes are fully derived from note/post markdown bodies, so dropping existing
/// rows is safe — they are re-materialised the next time each note or post is saved.
/// Run a backfill (edit-and-save each note/post, or a dedicated CLI command) after
/// this migration to repopulate quotes from all existing content.
struct RefactorQuotesTable: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }

        // Drop old indexes before dropping the table
        try await sqlDB.drop(index: "note_id_index").run()

        try await database.schema(Quote.schema).delete()

        try await database.schema(Quote.schema)
            .field("id", .uuid, .identifier(auto: false), .required)
            .field("note_id", .uuid)
            .field("post_id", .int)
            .field("body", .string, .required)
            .field("created_at", .datetime)
            .foreignKey("note_id", references: "notes", "id", onDelete: .cascade)
            .foreignKey("post_id", references: "posts", "id", onDelete: .cascade)
            .create()

        try await sqlDB.create(index: "quotes_note_id_index").on(Quote.schema).column("note_id").run()
        try await sqlDB.create(index: "quotes_post_id_index").on(Quote.schema).column("post_id").run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }

        try? await sqlDB.drop(index: "quotes_note_id_index").run()
        try? await sqlDB.drop(index: "quotes_post_id_index").run()

        try await database.schema(Quote.schema).delete()

        // Restore the original schema (Int PK, required note_id)
        try await database.schema(Quote.schema)
            .field("id", .int, .identifier(auto: true), .required)
            .field("note_id", .int, .required)
            .field("body", .string, .required)
            .field("created_at", .datetime)
            .foreignKey("note_id", references: "notes", "id", onDelete: .cascade)
            .create()

        try await sqlDB.create(index: "note_id_index").on(Quote.schema).column("note_id").run()
    }
}
