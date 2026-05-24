import Fluent
import Foundation
import SQLKit

struct CreateContainerEntries: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ContainerEntry.schema)
            .id()
            .field("container_type", .string, .required)
            .field("container_id", .int, .required)
            .field("preview_id", .uuid, .required, .references(Preview.schema, "id", onDelete: .cascade))
            .field("position", .int, .required)
            .unique(on: "container_type", "container_id", "preview_id")
            .create()

        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "idx_container_entries")
                .on(ContainerEntry.schema)
                .column("container_type")
                .column("container_id")
                .column("position")
                .run()
        }
    }

    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB.drop(index: "idx_container_entries").run()
        }
        try await database.schema(ContainerEntry.schema).delete()
    }
}
