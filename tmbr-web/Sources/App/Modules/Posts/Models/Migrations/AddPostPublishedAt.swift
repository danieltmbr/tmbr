import Fluent
import Foundation
import SQLKit

struct AddPostPublishedAt: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }

        try await sqlDB.raw("ALTER TABLE posts ADD COLUMN published_at TIMESTAMPTZ").run()

        try await sqlDB.raw("""
            UPDATE posts
            SET published_at = (date_trunc('day', created_at) + INTERVAL '12 hours') AT TIME ZONE 'UTC'
            WHERE state = 'published'
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE posts DROP COLUMN IF EXISTS published_at").run()
    }
}
