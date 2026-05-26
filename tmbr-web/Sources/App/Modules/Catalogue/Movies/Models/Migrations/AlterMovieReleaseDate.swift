import Fluent
import SQLKit

struct AlterMovieReleaseDate: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("AlterMovieReleaseDate requires SQL database")
            return
        }
        try await sql.raw("""
            ALTER TABLE movies
              ADD COLUMN IF NOT EXISTS director TEXT,
              ADD COLUMN IF NOT EXISTS genre TEXT,
              ALTER COLUMN release_date DROP NOT NULL
            """).run()
    }

    func revert(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            database.logger.warning("AlterMovieReleaseDate requires SQL database")
            return
        }
        try await sql.raw("""
            ALTER TABLE movies
              DROP COLUMN IF EXISTS director,
              DROP COLUMN IF EXISTS genre,
              ALTER COLUMN release_date SET NOT NULL
            """).run()
    }
}
