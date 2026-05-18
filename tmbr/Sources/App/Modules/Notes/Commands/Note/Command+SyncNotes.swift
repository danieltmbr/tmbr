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

    private let attachPermission: AuthPermissionResolver<AttachNotePermissionInput>

    private let createPermission: AuthPermissionResolver<Void>

    private let editPermission: AuthPermissionResolver<Note>

    private let deletePermission: AuthPermissionResolver<Note>

    private let database: Database

    init(
        attachPermission: AuthPermissionResolver<AttachNotePermissionInput>,
        createPermission: AuthPermissionResolver<Void>,
        editPermission: AuthPermissionResolver<Note>,
        deletePermission: AuthPermissionResolver<Note>,
        database: Database
    ) {
        self.attachPermission = attachPermission
        self.createPermission = createPermission
        self.editPermission = editPermission
        self.deletePermission = deletePermission
        self.database = database
    }

    func execute(_ input: SyncNotesInput) async throws -> [Note] {
        let attachmentID = try input.attachment.requireID()

        // Load all existing notes for this attachment and index by ID
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
                // Only act on notes that belong to this attachment — prevents cross-attachment mutations
                guard let note = existingByID[noteID] else { continue }

                if entry.deleted {
                    try await deletePermission.grant(note)
                    try await note.delete(on: database)
                } else {
                    let effectiveAccess = entry.access && input.parentAccess
                    if note.body != entry.body || note.access != effectiveAccess {
                        try await editPermission.grant(note)
                        note.body = entry.body
                        note.access = effectiveAccess
                        try await note.save(on: database)
                    }
                    results.append(note)
                }
            } else if !entry.deleted {
                let body = entry.body.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !body.isEmpty else { continue }
                let user = try await createPermission.grant()
                let note = Note(
                    attachmentID: attachmentID,
                    authorID: user.userID,
                    access: input.parentAccess && entry.access,
                    body: body
                )
                try await attachPermission(note, to: input.attachment)
                try await note.save(on: database)
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
                attachPermission: request.permissions.notes.attach,
                createPermission: request.permissions.notes.create,
                editPermission: request.permissions.notes.edit,
                deletePermission: request.permissions.notes.delete,
                database: request.commandDB
            )
            .logged(logger: request.logger)
        }
    }
}
