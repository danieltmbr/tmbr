import Fluent
import Foundation
import SQLKit

struct CreatePreview: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Preview.schema)
            .field("id", .int, .identifier(auto: true))
            .field("owner_type", .string, .required)
            .field("owner_id", .int, .required)
            .field("primary_info", .string, .required)
            .field("secondary_info", .string)
            .field("image_url", .string)
            .field("links", .array(of: .string), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "owner_type", "owner_id")
            .create()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "owner_id_index")
                .on(Note.schema)
                .column("owner_id")
                .run()
        }
    }

    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "owner_id_index")
                .run()
        }
        try await database.schema(Preview.schema).delete()
    }
}
