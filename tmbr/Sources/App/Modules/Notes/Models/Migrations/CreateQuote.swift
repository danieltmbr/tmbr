import Fluent
import Foundation
import PostgresKit

struct CreateQuote: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("quotes")
            .field("id", .int, .identifier(auto: true), .required)
            .field("note_id", .int, .required)
            .field("text", .string, .required)
            .field("created_at", .datetime)
            .foreignKey("note_id", references: "notes", "id", onDelete: .cascade)
            .create()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "note_id_index")
                .on(Quote.schema)
                .column("note_id")
                .run()
        }
    }
    
    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "note_id_index")
                .run()
        }
        
        try await database.schema(Quote.schema).delete()
    }
}
