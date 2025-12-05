import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditNoteInput: Sendable {
    
    let id: NoteID
    
    let access: Access
    
    let body: String
    
    func validate() throws {
        guard !body.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "Body is required")
        }
    }
}

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
    
    func execute(_ input: EditNoteInput) async throws -> Note {
        guard let note = try await Note.find(input.id, on: database) else {
            throw Abort(.notFound)
        }
        try await permission.grant(note)
        try await note.$attachment.load(on: database)
        try input.validate()
        note.body = input.body
        note.access = input.access && note.attachment.parentAccess
        try await note.save(on: database)
        return note
    }
}

extension CommandFactory<EditNoteInput, Note> {
    
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

extension CommandResolver where Input == EditNoteInput {
    
    func callAsFunction(
        _ noteID: NoteID,
        with payload: NotePayload
    ) async throws -> Output {
        let input = EditNoteInput(
            id: noteID,
            access: payload.access,
            body: payload.body
        )
        return try await self.callAsFunction(input)
    }
}
