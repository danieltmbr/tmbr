import Fluent
import Foundation
import SQLKit

struct MigratePreviewToCategoryID: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("""
            ALTER TABLE previews
            ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES catalogue_categories(id)
            """).run()
        try await sqlDB.raw("""
            UPDATE previews p
            SET category_id = (SELECT id FROM catalogue_categories WHERE slug = p.parent_type)
            WHERE p.parent_type IS NOT NULL
            """).run()
        try await sqlDB.raw("ALTER TABLE previews DROP COLUMN IF EXISTS parent_type").run()
        try await sqlDB.raw("ALTER TABLE previews DROP COLUMN IF EXISTS category").run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("""
            ALTER TABLE previews
            ADD COLUMN IF NOT EXISTS parent_type VARCHAR
            """).run()
        try await sqlDB.raw("""
            UPDATE previews p
            SET parent_type = (SELECT slug FROM catalogue_categories WHERE id = p.category_id)
            WHERE p.category_id IS NOT NULL
            """).run()
        try await sqlDB.raw("ALTER TABLE previews DROP COLUMN IF EXISTS category_id").run()
    }
}
