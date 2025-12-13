import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct BatchCreateNoteInput: Sendable {

    let attachment: Preview
    
    let notes: [NoteInput]
}

struct BatchCreateNoteCommand: Command {
    
    typealias Input = BatchCreateNoteInput
    
    typealias Output = [Note]
    
    private let attachPermission: AuthPermissionResolver<AttachNotePermissionInput>

    private let createPermission: AuthPermissionResolver<Void>

    private let database: Database

    init(
        attachPermission: AuthPermissionResolver<AttachNotePermissionInput>,
        createPermission: AuthPermissionResolver<Void>,
        database: Database
    ) {
        self.attachPermission = attachPermission
        self.createPermission = createPermission
        self.database = database
    }

    func execute(_ input: BatchCreateNoteInput) async throws -> [Note] {
        let user = try await createPermission.grant()
        let attachmentID = try input.attachment.requireID()
        let notes = input.notes.map {
            Note(
                attachmentID: attachmentID,
                authorID: user.userID,
                access: input.attachment.parentAccess && $0.access,
                body: $0.body
            )
        }
        try await attachPermission(notes, to: input.attachment)
        try await notes.create(on: database)
        return notes
    }
}

extension CommandFactory<BatchCreateNoteInput, [Note]> {

    static var createNotes: Self {
        CommandFactory { request in
            BatchCreateNoteCommand(
                attachPermission: request.permissions.notes.attach,
                createPermission: request.permissions.notes.create,
                database: request.commandDB
            )
            .logged(logger: request.logger)
        }
    }
}

extension CommandResolver where Input == BatchCreateNoteInput {
    
    func callAsFunction(
        _ notes: [NoteInput],
        for preview: Preview
    ) async throws -> Output {
        let input = BatchCreateNoteInput(
            attachment: preview,
            notes: notes
        )
        return try await self.callAsFunction(input)
    }
}
