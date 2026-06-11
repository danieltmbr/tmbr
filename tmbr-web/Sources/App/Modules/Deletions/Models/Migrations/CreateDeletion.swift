import Fluent
import SQLKit

struct CreateDeletion: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema(Deletion.schema)
            .id()
            .field("type", .string, .required)
            .field("item_id", .string, .required)
            .field("deleted_at", .datetime, .required)
            .create()

        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "deletions_deleted_at_index")
                .on(Deletion.schema)
                .column("deleted_at")
                .run()
        }
    }

    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB.drop(index: "deletions_deleted_at_index").run()
        }
        try await database.schema(Deletion.schema).delete()
    }
}
