import Fluent
import SQLKit

struct ChangeNoteIDToUUID: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("ChangeNoteIDToUUID requires SQL database")
            return
        }

        // Drop all FK constraints on quotes.note_id (different naming conventions)
        try await sql.raw("""
            ALTER TABLE quotes
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+notes.id"
            """).run()

        try await sql.raw("""
            ALTER TABLE quotes
            DROP CONSTRAINT IF EXISTS "fk:quotes.note_id+quotes.id"
            """).run()

        // Drop primary key constraint first
        try await sql.raw("""
            ALTER TABLE notes DROP CONSTRAINT IF EXISTS "pk:notes" CASCADE
            """).run()

        try await sql.raw("""
            ALTER TABLE notes DROP CONSTRAINT IF EXISTS notes_pkey CASCADE
            """).run()

        // Drop identity/serial
        try await sql.raw("""
            ALTER TABLE notes ALTER COLUMN id DROP IDENTITY IF EXISTS
            """).run()

        try await sql.raw("""
            ALTER TABLE notes ALTER COLUMN id DROP DEFAULT
            """).run()

        // Change notes.id type to UUID
        try await sql.raw("""
            ALTER TABLE notes ALTER COLUMN id TYPE uuid USING gen_random_uuid()
            """).run()

        // Re-add primary key
        try await sql.raw("""
            ALTER TABLE notes ADD PRIMARY KEY (id)
            """).run()

        // Change quotes.note_id from Int to UUID
        try await sql.raw("""
            ALTER TABLE quotes ALTER COLUMN note_id TYPE uuid USING gen_random_uuid()
            """).run()

        // Re-add FK as deferrable (quotes are created in middleware before note is committed)
        try await sql.raw("""
            ALTER TABLE quotes
            ADD CONSTRAINT "fk:quotes.note_id+notes.id"
                FOREIGN KEY (note_id) REFERENCES notes(id)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED
            """).run()
    }

    func revert(on database: Database) async throws {
        // Not reverting - would lose data
        database.logger.warning("ChangeNoteIDToUUID revert not implemented")
    }
}
