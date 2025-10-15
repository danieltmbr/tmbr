import Fluent

struct CreateMediaNotes: AsyncMigration {
    func prepare(on database: Database) async throws {
        let noteType = try await database.enum("media_note_type")
            .case("quote")
            .case("note")
            .create()
        
        let noteState = try await database.enum("media_note_state")
            .case("published")
            .case("draft")
            .create()
        
        try await database.schema("media_notes")
            .field("id", .int, .identifier(auto: true))
            .field("media_id", .int, .required, .references("media", "id", onDelete: .cascade))
            .field("author_id", .int, .required, .references("users", "id", onDelete: .cascade))
            .field("type", noteType, .required)
            .field("text", .string, .required)
            .field("commentary", .string)
            .field("position_start", .string)
            .field("position_end", .string)
            .field("state", noteState, .required)
            .field("created_at", .datetime, .required, .custom("DEFAULT CURRENT_TIMESTAMP"))
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("media_notes").delete()
        try await database.enum("media_note_state").delete()
        try await database.enum("media_note_type").delete()
    }
}

