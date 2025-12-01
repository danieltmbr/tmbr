import Foundation
import Core
import AuthKit
import Vapor
import Fluent

extension Permission<Preview> {
    
    static var accessPreview: Permission<Preview> {
        Permission<Preview>(
            "Only its owners can access private items and their previews."
        ) { user, preview in
            if preview.parentAccess == .public { return true }
            guard let user else { throw Abort(.unauthorized) }
            return preview.$parentOwner.id == user.userID || user.role == .admin
        }
    }
}

extension AuthPermission<Preview> {
    
    static var editPreview: Self {
        AuthPermission<Preview>(
            "Only its owners can edit a preview."
        ) { user, preview in
            preview.$parentOwner.id == user.userID || user.role == .admin
        }
    }
}


extension Permission<QueryBuilder<Preview>> {
    
    static var queryPreview: Permission<QueryBuilder<Preview>> {
        Permission<QueryBuilder<Preview>> { user, query in
            query.group(.or) { group in
                group.filter(\.$parentAccess == .public)
                if let userID = user?.id {
                    group.filter(\.$parentOwner.$id == userID)
                }
            }
        }
    }
}
