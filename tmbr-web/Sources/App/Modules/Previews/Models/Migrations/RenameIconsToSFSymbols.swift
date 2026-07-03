import Fluent
import SQLKit

struct RenameIconsToSFSymbols: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        let updates: [(slug: String, icon: String)] = [
            ("song",     "music.note"),
            ("album",    "music.note.square.stack"),
            ("book",     "book.closed"),
            ("movie",    "movieclapper"),
            ("playlist", "music.note.list"),
            ("podcast",  "microphone"),
            ("track",    "music.note"),
        ]
        for row in updates {
            try await sqlDB.raw("""
                UPDATE catalogue_categories
                SET icon = \(literal: row.icon)
                WHERE slug = \(literal: row.slug)
                """).run()
        }
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        let updates: [(slug: String, icon: String)] = [
            ("song",     "song"),
            ("album",    "album"),
            ("book",     "book"),
            ("movie",    "movie"),
            ("playlist", "playlist"),
            ("podcast",  "podcast"),
            ("track",    "song"),
        ]
        for row in updates {
            try await sqlDB.raw("""
                UPDATE catalogue_categories
                SET icon = \(literal: row.icon)
                WHERE slug = \(literal: row.slug)
                """).run()
        }
    }
}
