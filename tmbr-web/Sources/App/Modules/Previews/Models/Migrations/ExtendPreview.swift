import Fluent
import Foundation
import SQLKit

struct ExtendPreview: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw(#"ALTER TABLE previews DROP CONSTRAINT IF EXISTS "uq:previews.parent_type+parent_id""#).run()
        try await sqlDB.raw("ALTER TABLE previews ALTER COLUMN parent_id DROP NOT NULL").run()
        try await sqlDB.raw("""
            CREATE UNIQUE INDEX uq_previews_parent_type_parent_id
            ON previews (parent_type, parent_id)
            WHERE parent_id IS NOT NULL
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("DROP INDEX IF EXISTS uq_previews_parent_type_parent_id").run()
        try await sqlDB.raw("ALTER TABLE previews ALTER COLUMN parent_id SET NOT NULL").run()
        try await sqlDB.raw(#"ALTER TABLE previews ADD CONSTRAINT "uq:previews.parent_type+parent_id" UNIQUE (parent_type, parent_id)"#).run()
    }
}
