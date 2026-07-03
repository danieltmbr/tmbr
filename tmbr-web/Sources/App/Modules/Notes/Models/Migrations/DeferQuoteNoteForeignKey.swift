import Fluent
import SQLKit

/// Makes the `note_id` foreign key on `quotes` deferrable.
///
/// NoteModelMiddleware inserts quote rows immediately after each note's middleware
/// chain runs, but Fluent's batch create doesn't INSERT notes until all middleware
/// chains complete. Making the constraint deferred lets quote rows reference note IDs
/// that are committed in the same transaction before the transaction closes.
struct DeferQuoteNoteForeignKey: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DeferQuoteNoteForeignKey requires SQL database")
            return
        }
        try await sql.raw("""
            ALTER TABLE quotes
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+quotes.id",
            ADD CONSTRAINT "fk:quotes.note_id+notes.id"
                FOREIGN KEY (note_id) REFERENCES notes(id)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("""
            ALTER TABLE quotes
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+notes.id",
            ADD CONSTRAINT "fk:quotes.note_id+quotes.id"
                FOREIGN KEY (note_id) REFERENCES notes(id)
                ON DELETE CASCADE
            """).run()
    }
}
