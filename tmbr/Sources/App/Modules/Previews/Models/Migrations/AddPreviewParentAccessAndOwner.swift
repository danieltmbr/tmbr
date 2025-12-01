import Fluent
import Vapor

struct AddPreviewParentAccessAndOwner: AsyncMigration {
    func prepare(on database: Database) async throws {
        let accessType = try await database.enum("access").read()
        try await database.schema(Preview.schema)
            .field("parent_access", accessType, .required)
            .field("parent_owner", .int, .required)
            .foreignKey("parent_owner", references: "users", "id", onDelete: .restrict)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Preview.schema)
            .deleteField("parent_access")
            .deleteField("parent_owner")
            .update()
    }
}
