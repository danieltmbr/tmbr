import Fluent
import Foundation
import SQLKit

/// Strips stray single quotes from language values caused by a double-quoting
/// bug in the original AddPostPublishedAtAndLanguage / AddNoteLanguage migrations,
/// which stored 'en' (4 bytes with quotes) instead of en (2 bytes).
struct FixLanguageFieldValues: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("UPDATE posts SET language = REPLACE(language, '''', '')").run()
        try await sqlDB.raw("UPDATE notes SET language = REPLACE(language, '''', '')").run()
    }

    func revert(on database: Database) async throws {}
}
