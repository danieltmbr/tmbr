import Fluent
import Foundation
import SQLKit

struct CreatePreview: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Preview.schema)
            .field("id", .uuid, .identifier(auto: false))
            .field("parent_type", .string, .required)
            .field("parent_id", .int, .required)
            .field("primary_info", .string, .required)
            .field("secondary_info", .string)
            .field("image_id", .int)
            .field("links", .array(of: .string), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "parent_type", "parent_id")
            .create()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "parent_id_index")
                .on(Note.schema)
                .column("parent_id")
                .run()
        }
    }

    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "parent_id_index")
                .run()
        }
        try await database.schema(Preview.schema).delete()
    }
}
