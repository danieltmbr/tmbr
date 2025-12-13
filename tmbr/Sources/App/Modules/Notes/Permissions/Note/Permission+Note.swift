import Foundation
import Core
import AuthKit
import Vapor
import Fluent

extension AuthPermission<Void> {
    
    static var createNote: Self {
        AuthPermission<Void>(
            "Only authors can create notes."
        ) { user, _ in
            user.role == .author || user.role == .admin
        }
    }
}

extension AuthPermission<Note> {
    
    static var deleteNote: Self {
        AuthPermission<Note>(
            "Only its author can delete a note."
        ) { user, note in
            note.$author.id == user.userID || user.role == .admin
        }
    }
    
    static var editNote: Self {
        AuthPermission<Note>(
            "Only its author can edit a note."
        ) { user, note in
            note.$author.id == user.userID || user.role == .admin
        }
    }
}

extension Permission<QueryBuilder<Note>> {
    
    static var queryNote: Permission<QueryBuilder<Note>> {
        Permission<QueryBuilder<Note>> { user, query in
            query.group(.or) { group in
                group.filter(\.$access == .public)
                if let userID = user?.id {
                    group.filter(\.$author.$id == userID)
                }
            }
        }
    }
}

struct AttachNotePermissionInput: Sendable {
    
    let notes: [Note]
    
    let preview: Preview
    
    init(notes: [Note], preview: Preview) {
        self.notes = notes
        self.preview = preview
    }
    
    init(note: Note, preview: Preview) {
        self.notes = [note]
        self.preview = preview
    }
}

extension AuthPermission<AttachNotePermissionInput> {
    
    static var attachNote: Self {
        AuthPermission<AttachNotePermissionInput>(
            "Only the item's authors can add notes to it."
        ) { user, input in
            let authorIDs = Set(input.notes.compactMap(\.author.id))
            guard authorIDs.count == 1 else { return false }
            let authorID = authorIDs.first!
            return authorID == user.userID && authorID == input.preview.parentOwner.id
        }
    }
}

extension PermissionResolver where Input == AttachNotePermissionInput {
    
    @discardableResult
    func callAsFunction(_ note: Note, to preview: Preview) async throws -> Output {
        try await callAsFunction(AttachNotePermissionInput(note: note, preview: preview))
    }
    
    @discardableResult
    func callAsFunction(_ notes: [Note], to preview: Preview) async throws -> Output {
        try await callAsFunction(AttachNotePermissionInput(notes: notes, preview: preview))
    }
}
