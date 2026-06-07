import Fluent
import Foundation
import SQLKit

struct CreateCatalogueCategories: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema("catalogue_categories")
            .id()
            .field("slug", .string, .required)
            .field("name", .string, .required)
            .field("kind", .string, .required)
            .unique(on: "slug")
            .create()

        guard let sqlDB = database as? SQLDatabase else { return }
        let seeds: [(slug: String, name: String, kind: String)] = [
            ("song",     "Songs",     "catalogue"),
            ("album",    "Albums",    "catalogue"),
            ("book",     "Books",     "catalogue"),
            ("movie",    "Movies",    "catalogue"),
            ("playlist", "Playlists", "catalogue"),
            ("podcast",  "Podcasts",  "catalogue"),
            ("track",    "Tracks",    "promotable"),
        ]
        for seed in seeds {
            try await sqlDB.raw("""
                INSERT INTO catalogue_categories (id, slug, name, kind)
                VALUES (gen_random_uuid(), \(literal: seed.slug), \(literal: seed.name), \(literal: seed.kind))
                ON CONFLICT (slug) DO NOTHING
                """).run()
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("catalogue_categories").delete()
    }
}
