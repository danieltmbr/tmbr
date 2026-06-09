import Fluent
import Foundation
import SQLKit

struct RenameCatalogueKinds: AsyncMigration {

    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("UPDATE catalogue_categories SET kind = 'entry' WHERE kind = 'catalogue'").run()
        try await sqlDB.raw("UPDATE catalogue_categories SET kind = 'virtual' WHERE kind = 'collection'").run()
    }

    func revert(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("UPDATE catalogue_categories SET kind = 'catalogue' WHERE kind = 'entry'").run()
        try await sqlDB.raw("UPDATE catalogue_categories SET kind = 'collection' WHERE kind = 'virtual'").run()
    }
}
