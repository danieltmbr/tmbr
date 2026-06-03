import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit
import TmbrCore

struct EditNoteInput: Sendable {

    let id: NoteID

    let access: Access

    let body: String

    let language: Language

    init(id: NoteID, access: Access, body: String, language: Language = .en) {
        self.id = id
        self.access = access
        self.body = body
        self.language = language
    }

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
        note.language = input.language
        try await note.save(on: database)
        return note
    }
}

extension CommandFactory<EditNoteInput, Note> {
    
    static var editNote: Self {
        CommandFactory { request in
            EditNoteCommand(
                database: request.commandDB,
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
            body: payload.body,
            language: payload.language ?? .en
        )
        return try await self.callAsFunction(input)
    }
}
