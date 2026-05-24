import Fluent
import SQLKit

/// Makes the `preview_id` foreign key constraints on catalogue items deferrable.
///
/// This allows the PreviewModelMiddleware to save the parent entity (Song, Book, etc.)
/// before the Preview exists, with the FK constraint only being checked at transaction commit.
struct DeferPreviewForeignKeys: AsyncMigration {

    private let tables = ["songs", "books", "movies", "podcasts"]

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DeferPreviewForeignKeys requires SQL database")
            return
        }

        for table in tables {
            // Drop existing constraint and re-add as deferrable
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                DROP CONSTRAINT IF EXISTS "fk:\(unsafeRaw: table).preview_id+\(unsafeRaw: table).id",
                ADD CONSTRAINT "fk:\(unsafeRaw: table).preview_id+previews.id"
                    FOREIGN KEY (preview_id) REFERENCES previews(id)
                    ON DELETE CASCADE
                    DEFERRABLE INITIALLY DEFERRED
                """).run()
        }
    }
    
    func revert(on database: Database) async throws {}
}
