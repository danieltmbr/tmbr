import Fluent
import Foundation
import SQLKit

struct AddPreviewCategory: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE previews ALTER COLUMN parent_type DROP NOT NULL").run()
        try await sqlDB.raw("ALTER TABLE previews ADD COLUMN IF NOT EXISTS category VARCHAR").run()
        // Backfill: move parentType into category for existing user-created orphans (not track placeholders).
        try await sqlDB.raw("""
            UPDATE previews
            SET category = parent_type, parent_type = NULL
            WHERE parent_id IS NULL AND parent_type IS NOT NULL AND parent_type != 'track'
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("""
            UPDATE previews
            SET parent_type = category, category = NULL
            WHERE parent_id IS NULL AND parent_type IS NULL AND category IS NOT NULL
            """).run()
        try await sqlDB.raw("ALTER TABLE previews DROP COLUMN IF EXISTS category").run()
        try await sqlDB.raw("ALTER TABLE previews ALTER COLUMN parent_type SET NOT NULL").run()
    }
}
