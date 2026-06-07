import Fluent
import SQLKit

struct AddRouteAndIconToCatalogueCategories: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema("catalogue_categories")
            .field("route", .string)
            .field("icon", .string)
            .update()

        guard let sqlDB = database as? SQLDatabase else { return }
        let updates: [(slug: String, route: String, icon: String)] = [
            ("song",     "songs",     "song"),
            ("album",    "albums",    "album"),
            ("book",     "books",     "book"),
            ("movie",    "movies",    "movie"),
            ("playlist", "playlists", "playlist"),
            ("podcast",  "podcasts",  "podcast"),
            ("track",    "songs",     "song"),
        ]
        for row in updates {
            try await sqlDB.raw("""
                UPDATE catalogue_categories
                SET route = \(literal: row.route), icon = \(literal: row.icon)
                WHERE slug = \(literal: row.slug)
                """).run()
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("catalogue_categories")
            .deleteField("route")
            .deleteField("icon")
            .update()
    }
}
