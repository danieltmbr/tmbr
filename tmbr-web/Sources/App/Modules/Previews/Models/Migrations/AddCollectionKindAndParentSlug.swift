import Fluent
import Foundation
import SQLKit

struct AddCollectionKindAndParentSlug: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema("catalogue_categories")
            .field("parent_slug", .string)
            .update()

        guard let sqlDB = database as? SQLDatabase else { return }

        // Add FK constraint: parent_slug references slug in the same table
        try await sqlDB.raw("""
            ALTER TABLE catalogue_categories
            ADD CONSTRAINT catalogue_categories_parent_slug_fkey
            FOREIGN KEY (parent_slug) REFERENCES catalogue_categories(slug)
            """).run()

        // Seed the music collection
        try await sqlDB.raw("""
            INSERT INTO catalogue_categories (slug, name, kind, route, icon)
            VALUES ('music', 'Music', 'collection', 'music', 'music')
            ON CONFLICT (slug) DO UPDATE SET kind = 'collection', route = 'music', icon = 'music'
            """).run()

        // Link music sub-categories to the collection
        try await sqlDB.raw("""
            UPDATE catalogue_categories SET parent_slug = 'music'
            WHERE slug IN ('song', 'album', 'playlist')
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }

        // Unlink sub-categories
        try await sqlDB.raw("UPDATE catalogue_categories SET parent_slug = NULL WHERE slug IN ('song', 'album', 'playlist')").run()

        // Remove music collection entry
        try await sqlDB.raw("DELETE FROM catalogue_categories WHERE slug = 'music' AND kind = 'collection'").run()

        // Drop FK constraint and column
        try await sqlDB.raw("ALTER TABLE catalogue_categories DROP CONSTRAINT IF EXISTS catalogue_categories_parent_slug_fkey").run()

        try await database.schema("catalogue_categories")
            .deleteField("parent_slug")
            .update()
    }
}
