import Fluent
import Foundation
import SQLKit

struct AddPostLanguage: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE posts ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'en'").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Post.schema)
            .deleteField("language")
            .update()
    }
}
