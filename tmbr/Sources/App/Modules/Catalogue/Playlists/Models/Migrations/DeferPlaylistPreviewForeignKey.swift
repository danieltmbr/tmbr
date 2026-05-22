import Fluent
import SQLKit

struct DeferPlaylistPreviewForeignKey: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DeferPlaylistPreviewForeignKey requires SQL database")
            return
        }
        try await sql.raw("""
            ALTER TABLE playlists
            DROP CONSTRAINT IF EXISTS "fk:playlists.preview_id+playlists.id",
            ADD CONSTRAINT "fk:playlists.preview_id+previews.id"
                FOREIGN KEY (preview_id) REFERENCES previews(id)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED
            """).run()
    }

    func revert(on database: Database) async throws {}
}
