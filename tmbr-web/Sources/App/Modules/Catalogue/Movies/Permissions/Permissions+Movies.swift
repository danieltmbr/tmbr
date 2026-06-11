import AuthKit
import Fluent
import TmbrCore

extension PermissionScopes {
    var movies: PreviewablePermissionScope<Movie>.Type { PreviewablePermissionScope<Movie>.self }
}

extension PreviewablePermissionScope<Movie> {
    static var movies: Self {
        PreviewablePermissionScope(
            access: .access("This movie is private."),
            create: .create("You don't have permission to create a movie."),
            delete: .delete("Only its owner can delete a movie."),
            edit: .edit("Only its owner can edit a movie."),
            list: .listOwned(owner: \.$owner.$id),
            query: .query(access: \.$access, owner: \.$owner.$id)
        )
    }

    var lookup: Permission<QueryBuilder<Movie>> {
        Permission { user, query in
            guard let userID = user?.userID else { return }
            query.filter(\.$owner.$id == userID)
        }
    }
}
