import Fluent
import SQLKit

/// Makes the quote's note_id foreign key constraint deferrable.
///
/// Quotes are created in the NoteModelMiddleware before the note is committed,
/// so the FK check needs to be deferred to transaction commit.
struct DeferQuoteForeignKey: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DeferQuoteForeignKey requires SQL database")
            return
        }

        try await sql.raw("""
            ALTER TABLE quotes
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+notes.id"
            """).run()

        try await sql.raw("""
            ALTER TABLE quotes
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
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+notes.id"
            """).run()

        try await sql.raw("""
            ALTER TABLE quotes
            ADD CONSTRAINT "fk:quotes.note_id+notes.id"
                FOREIGN KEY (note_id) REFERENCES notes(id)
                ON DELETE CASCADE
            """).run()
    }
}
