import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<NoteID, Void> {
    static func deleteNote(
        database: Database,
        permission: AuthPermissionResolver<Note>
    ) -> Self {
        PlainCommand { noteID in
            guard let note = try await Note.find(noteID, on: database) else {
                throw Abort(.notFound, reason: "Note not found")
            }
            try await permission.grant(note)
            try await note.delete(on: database)
        }
    }
}

extension CommandFactory<NoteID, Void> {
    
    static var deleteNote: Self {
        CommandFactory { request in
            .deleteNote(
                database: request.commandDB,
                permission: request.permissions.notes.delete
            )
            .logged(name: "Delete Note", logger: request.logger)
        }
    }
}
