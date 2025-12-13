import Foundation
import AuthKit
import Vapor
import Fluent

// MARK: - Create
extension AuthPermission<Void> {
    static func create(_ reason: String) -> Self {
        AuthPermission<Void>(reason) { user, _ in
            user.role == .author || user.role == .admin
        }
    }
}

// MARK: - Edit/Delete
extension AuthPermission where Input: Previewable {
    static func edit(_ reason: String) -> Self {
        AuthPermission(reason) { user, item in
            item.ownerID == user.userID || user.role == .admin
        }
    }
    
    static func delete(_ reason: String) -> Self {
        AuthPermission(reason) { user, item in
            item.ownerID == user.userID || user.role == .admin
        }
    }
}

// MARK: - Fetch / Access
extension Permission where Input: Previewable {
    static func access(_ reason: String) -> Self {
        Permission(reason) { user, item in
            if item.access == .public { return true }
            guard let user else { throw Abort(.unauthorized) }
            return item.ownerID == user.userID || user.role == .admin
        }
    }
}

extension Permission {
    
    static func query<M: Model, A, O>(
        access: KeyPath<M, A>,
        owner: KeyPath<M, O>
    ) -> Permission<QueryBuilder<M>>
    where M: Previewable,
          A: QueryableProperty, A.Model == M, A.Value == Access,
          O: QueryableProperty, O.Model == M, O.Value == UserID,
          Input == QueryBuilder<M>
    {
        Permission { (user: User?, query: Input) in
            query.group(.or) { group in
                group.filter(access == .public)
                if let userID = user?.id {
                    group.filter(owner == userID)
                }
            }
        }
    }
}

