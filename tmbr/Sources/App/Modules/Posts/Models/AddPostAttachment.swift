import Fluent
import Foundation
import SQLKit

struct AddPostAttachment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Post.schema)
            .field("attachment_type", .string)
            .field("attachment_id", .int)
            .update()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "attachment_id_index")
                .on(Note.schema)
                .column("attachment_id")
                .run()
            
            try await sqlDB
                .create(index: "attachment_type_index")
                .on(Note.schema)
                .column("attachment_type")
                .run()
        }
    }
    
    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "attachment_id_index")
                .run()
            
            try await sqlDB
                .drop(index: "attachment_type_index")
                .run()
        }
        
        try await database.schema(Post.schema)
            .deleteField("attachment_type")
            .deleteField("attachment_id")
            .update()
    }
}
