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
                group.filter(\.$visibility == .public)
                if let userID = user?.id {
                    group.filter(\.$author.$id == userID)
                }
            }
        }
    }
}
