import Foundation
import Core
import AuthKit
import Vapor

extension Permission<Note> {
    static var accessNote: Permission<Note> {
        Permission<Note>(
            "This note is private. Only its author can see it."
        ) { user, note in
            if note.visibility == .public { return true }
            guard let user else { throw Abort(.unauthorized) }
            return note.$author.id == user.userID || user.role == .admin
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

extension AuthPermission<Void> {
    
    static var createNote: Self {
        AuthPermission<Void>(
            "Only authors can create notes."
        ) { user, _ in
            user.role == .author || user.role == .admin
        }
    }
}
