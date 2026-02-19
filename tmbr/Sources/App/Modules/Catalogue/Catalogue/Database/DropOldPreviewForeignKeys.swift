import Fluent
import SQLKit

/// Drops the old incorrectly-named preview_id foreign key constraints.
///
/// Fluent originally created constraints with names like `fk:songs.preview_id+songs.id`
/// (referencing the table itself in the name, though actually pointing to previews).
/// The DeferPreviewForeignKeys migration added the correct deferrable constraints,
/// but couldn't drop the old ones due to the naming mismatch.
struct DropOldPreviewForeignKeys: AsyncMigration {

    private let tables = ["songs", "books", "movies", "podcasts"]

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DropOldPreviewForeignKeys requires SQL database")
            return
        }

        for table in tables {
            // Drop the old constraint with the incorrect name pattern
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                DROP CONSTRAINT IF EXISTS "fk:\(unsafeRaw: table).preview_id+\(unsafeRaw: table).id"
                """).run()
        }
    }

    func revert(on database: Database) async throws {
        // No-op: we don't want to recreate the incorrectly-named constraints
    }
}
