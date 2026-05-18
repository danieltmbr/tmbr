import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct SyncNoteEntry: Sendable {
    let id: NoteID?
    let body: String
    let access: Access
    let deleted: Bool
}

struct SyncNotesInput: Sendable {
    let attachment: Preview
    let parentAccess: Access
    let entries: [SyncNoteEntry]
}

struct SyncNotesCommand: Command {

    typealias Input = SyncNotesInput

    typealias Output = [Note]

    private let create: CommandResolver<CreateNoteInput, Note>

    private let edit: CommandResolver<EditNoteInput, Note>

    private let delete: CommandResolver<NoteID, Void>

    private let database: Database

    init(
        create: CommandResolver<CreateNoteInput, Note>,
        edit: CommandResolver<EditNoteInput, Note>,
        delete: CommandResolver<NoteID, Void>,
        database: Database
    ) {
        self.create = create
        self.edit = edit
        self.delete = delete
        self.database = database
    }

    func execute(_ input: SyncNotesInput) async throws -> [Note] {
        let attachmentID = try input.attachment.requireID()

        // Load all existing notes for this attachment and index by ID.
        // This membership check is the only guard against a payload that references
        // note IDs from a different attachment the user also owns.
        let existing = try await Note.query(on: database)
            .filter(\.$attachment.$id == attachmentID)
            .all()
        let existingByID = Dictionary(uniqueKeysWithValues: existing.compactMap { note -> (NoteID, Note)? in
            guard let id = note.id else { return nil }
            return (id, note)
        })

        var results: [Note] = []

        for entry in input.entries {
            if let noteID = entry.id {
                guard let note = existingByID[noteID] else { continue }

                if entry.deleted {
                    try await delete(noteID)
                } else {
                    let effectiveAccess = entry.access && input.parentAccess
                    if note.body != entry.body || note.access != effectiveAccess {
                        let updated = try await edit(EditNoteInput(id: noteID, access: entry.access, body: entry.body))
                        results.append(updated)
                    } else {
                        results.append(note)
                    }
                }
            } else if !entry.deleted {
                let body = entry.body.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !body.isEmpty else { continue }
                let note = try await create(CreateNoteInput(body: body, access: entry.access, attachmentID: attachmentID))
                results.append(note)
            }
        }

        return results
    }
}

extension CommandFactory<SyncNotesInput, [Note]> {

    static var syncNotes: Self {
        CommandFactory { request in
            SyncNotesCommand(
                create: request.commands.notes.create,
                edit: request.commands.notes.edit,
                delete: request.commands.notes.delete,
                database: request.commandDB
            )
            .logged(logger: request.logger)
        }
    }
}
