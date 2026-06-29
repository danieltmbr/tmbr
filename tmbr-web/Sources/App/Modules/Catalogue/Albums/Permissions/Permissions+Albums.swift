import WebAuth
import Fluent
import TmbrCore

extension PermissionScopes {
    var albums: PreviewablePermissionScope<Album>.Type { PreviewablePermissionScope<Album>.self }
}

extension PreviewablePermissionScope<Album> {
    static var albums: Self {
        PreviewablePermissionScope(
            access: .access("This album is private."),
            create: .create("You don't have permission to create an album."),
            delete: .delete("Only its owner can delete an album."),
            edit: .edit("Only its owner can edit an album."),
            query: .query(access: \.$access, owner: \.$owner.$id)
        )
    }

    var lookup: Permission<QueryBuilder<Album>> {
        Permission { user, query in
            guard let userID = user?.userID else { return }
            query.filter(\.$owner.$id == userID)
        }
    }
}
