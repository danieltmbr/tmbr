import Fluent
import Foundation
import SQLKit

struct CreateNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        let state = try await database.enum("note_state")
            .case("public")
            .case("private")
            .create()
        
        try await database.schema(Note.schema)
            .field("id", .int, .identifier(auto: true), .required)
            .field("author_id", .int, .required)
            .field("body", .string, .required)
            .field("state", state, .required)
            .field("attachment_id", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .foreignKey("author_id", references: "users", "id", onDelete: .cascade)
            .foreignKey("attachment_id", references: "previews", "id", onDelete: .cascade)
            .create()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "attachment_id_index")
                .on(Note.schema)
                .column("attachment_id")
                .run()
        }
    }
    
    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "attachment_id_index")
                .run()
        }
        
        try await database.schema("notes").delete()
    }
}
