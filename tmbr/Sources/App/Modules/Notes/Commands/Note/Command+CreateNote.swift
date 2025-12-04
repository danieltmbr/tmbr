import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateNoteInput: Decodable {
    var body: String
    
    var access: Access
    
    var attachmentID: UUID
}

struct CreateNoteCommand: Command {
    
    typealias Input = CreateNoteInput
    
    typealias Output = Note
    
    private let attachPermission: AuthPermissionResolver<AttachNotePermissionInput>

    private let createPermission: AuthPermissionResolver<Void>

    private let database: Database
    
    private let fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>

    init(
        attachPermission: AuthPermissionResolver<AttachNotePermissionInput>,
        createPermission: AuthPermissionResolver<Void>,
        database: Database,
        fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>
    ) {
        self.attachPermission = attachPermission
        self.createPermission = createPermission
        self.database = database
        self.fetchPreview = fetchPreview
    }

    func execute(_ input: CreateNoteInput) async throws -> Note {
        let user = try await createPermission.grant()
        let preview = try await fetchPreview(input.attachmentID, for: .write)
        let note = Note(
            attachmentID: input.attachmentID,
            authorID: user.userID,
            access: preview.parentAccess && input.access,
            body: input.body
        )
        try await attachPermission(note, to: preview)
        try await note.save(on: database)
        return note
    }
}

extension CommandFactory<CreateNoteInput, Note> {

    static var createNote: Self {
        CommandFactory { request in
            CreateNoteCommand(
                attachPermission: request.permissions.notes.attach,
                createPermission: request.permissions.notes.create,
                database: request.application.db,
                fetchPreview: request.commands.previews.fetch
            )
            .logged(logger: request.logger)
        }
    }
}
