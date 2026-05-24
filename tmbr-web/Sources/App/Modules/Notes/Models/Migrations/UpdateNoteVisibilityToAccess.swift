import Fluent
import SQLKit

struct UpdateNoteVisibilityToAccess: AsyncMigration {
    func prepare(on database: Database) async throws {
        let accessType = try await database.enum("access").read()

        try await database.schema(Note.schema)
            .field("access", accessType, .required)
            .update()

        if let sql = database as? SQLDatabase {
            try? await sql.raw("""
                UPDATE \"\(unsafeRaw: Note.schema)\"
                SET access = CASE note_visibility
                    WHEN 'public' THEN 'public'
                    WHEN 'private' THEN 'private'
                    ELSE 'private'
                END
                """).run()
        }

        try await database.schema(Note.schema)
            .deleteField("note_visibility")
            .update()

        try? await database.enum("note_visibility").delete()
    }

    func revert(on database: Database) async throws {
        let visibilityType: DatabaseSchema.DataType
        if let read = try? await database.enum("note_visibility").read() {
            visibilityType = read
        } else {
            visibilityType = try await database.enum("note_visibility")
                .case("public")
                .case("private")
                .create()
        }

        try? await database.schema(Note.schema)
            .field("note_visibility", visibilityType, .required)
            .update()

        if let sql = database as? SQLDatabase {
            try? await sql.raw("""
                UPDATE \"\(unsafeRaw: Note.schema)\"
                SET note_visibility = CASE access
                    WHEN 'public' THEN 'public'
                    WHEN 'private' THEN 'private'
                    ELSE 'private'
                END
                """).run()
        }

        try? await database.schema(Note.schema)
            .deleteField("access")
            .update()
    }
}
