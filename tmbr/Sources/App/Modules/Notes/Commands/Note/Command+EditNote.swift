import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditNoteCommand: Command {
    
    private let database: Database
        
    private let permission: AuthPermissionResolver<Note>
    
    init(
        database: Database,
        permission: AuthPermissionResolver<Note>
    ) {
        self.database = database
        self.permission = permission
    }
    
    func execute(_ payload: EditNotePayload) async throws -> Note {
        guard let note = try await Note.find(payload.id, on: database) else {
            throw Abort(.notFound)
        }
        try await permission.grant(note)
        try await note.$attachment.load(on: database)
        try payload.validate()
        note.body = payload.body
        note.access = payload.access && note.attachment.parentAccess
        try await note.save(on: database)
        return note
    }
}

extension CommandFactory<EditNotePayload, Note> {
    
    static var editNote: Self {
        CommandFactory { request in
            EditNoteCommand(
                database: request.application.db,
                permission: request.permissions.notes.edit
            )
            .logged(logger: request.logger)
        }
    }
}
