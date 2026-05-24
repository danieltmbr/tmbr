import Fluent
import SQLKit

struct DeferAlbumPreviewForeignKey: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("DeferAlbumPreviewForeignKey requires SQL database")
            return
        }
        try await sql.raw("""
            ALTER TABLE albums
            DROP CONSTRAINT IF EXISTS "fk:albums.preview_id+albums.id",
            ADD CONSTRAINT "fk:albums.preview_id+previews.id"
                FOREIGN KEY (preview_id) REFERENCES previews(id)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED
            """).run()
    }

    func revert(on database: Database) async throws {}
}
