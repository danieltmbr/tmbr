import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit
import TmbrCore

struct CreateNoteInput: Decodable {
    var body: String

    var access: Access

    var attachmentID: UUID

    var language: Language = .en
}

struct CreateNoteCommand: Command {

    typealias Input = CreateNoteInput

    typealias Output = Note

    private let attachPermission: AuthPermissionResolver<AttachNotePermissionInput>

    private let createPermission: AuthPermissionResolver<Void>

    private let database: Database

    private let fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>

    private let logger: Logger

    private let notify: CommandResolver<Note, Void>

    init(
        attachPermission: AuthPermissionResolver<AttachNotePermissionInput>,
        createPermission: AuthPermissionResolver<Void>,
        database: Database,
        fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>,
        logger: Logger,
        notify: CommandResolver<Note, Void>
    ) {
        self.attachPermission = attachPermission
        self.createPermission = createPermission
        self.database = database
        self.fetchPreview = fetchPreview
        self.logger = logger
        self.notify = notify
    }

    func execute(_ input: CreateNoteInput) async throws -> Note {
        let user = try await createPermission.grant()
        let preview = try await fetchPreview(input.attachmentID, for: .write)
        let note = Note(
            attachmentID: input.attachmentID,
            authorID: user.userID,
            access: preview.parentAccess && input.access,
            body: input.body,
            language: input.language
        )
        try await attachPermission(note, to: preview)
        try await note.save(on: database)
        if note.access == .public {
            let notify = self.notify
            let logger = self.logger
            Task.detached {
                do {
                    try await notify(note)
                } catch {
                    logger.error("Note notification failed: \(error)")
                }
            }
        }
        return note
    }
}

extension CommandFactory<CreateNoteInput, Note> {

    static var createNote: Self {
        CommandFactory { request in
            CreateNoteCommand(
                attachPermission: request.permissions.notes.attach,
                createPermission: request.permissions.notes.create,
                database: request.commandDB,
                fetchPreview: request.commands.previews.fetch,
                logger: request.logger,
                notify: request.commands.notifications.note
            )
            .logged(logger: request.logger)
        }
    }
}
