import Fluent
import Foundation
import SQLKit

struct AddCreatedAtToPlaylist: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE playlists ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Playlist.schema)
            .deleteField("created_at")
            .update()
    }
}
