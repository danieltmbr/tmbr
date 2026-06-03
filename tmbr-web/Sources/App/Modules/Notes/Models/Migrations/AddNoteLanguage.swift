import Fluent
import Foundation
import SQLKit

struct AddNoteLanguage: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE notes ADD COLUMN language TEXT NOT NULL DEFAULT 'en'").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Note.schema)
            .deleteField("language")
            .update()
    }
}
