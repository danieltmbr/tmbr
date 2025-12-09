import AuthKit
import Fluent

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
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}
