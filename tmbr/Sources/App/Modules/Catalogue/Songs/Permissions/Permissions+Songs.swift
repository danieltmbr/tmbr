import AuthKit
import Fluent

extension PermissionScopes {
    var songs: PreviewablePermissionScope<Song>.Type { PreviewablePermissionScope<Song>.self }
}

extension PreviewablePermissionScope<Song> {
    static var songs: Self {
        PreviewablePermissionScope(
            access: .access("This song is private."),
            create: .create("You don't have permission to create a song."),
            delete: .delete("Only its owner can delete a song."),
            edit: .edit("Only its owner can edit a song."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}
