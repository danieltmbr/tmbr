import Fluent
import Foundation
import SQLKit

struct AddPostAttachment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Post.schema)
            .field("attachment_id", .uuid)
            .update()
        
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .create(index: "post_attachment_id_index")
                .on(Post.schema)
                .column("attachment_id")
                .run()
        }
    }
    
    func revert(on database: Database) async throws {
        if let sqlDB = database as? SQLDatabase {
            try await sqlDB
                .drop(index: "post_attachment_id_index")
                .run()
        }
        
        try await database.schema(Post.schema)
            .deleteField("attachment_id")
            .update()
    }
}
