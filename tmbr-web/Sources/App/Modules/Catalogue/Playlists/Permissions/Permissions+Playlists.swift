import CoreAuth
import Fluent

extension PermissionScopes {
    var playlists: PreviewablePermissionScope<Playlist>.Type { PreviewablePermissionScope<Playlist>.self }
}

extension PreviewablePermissionScope<Playlist> {
    static var playlists: Self {
        PreviewablePermissionScope(
            access: .access("This playlist is private."),
            create: .create("You don't have permission to create a playlist."),
            delete: .delete("Only its owner can delete a playlist."),
            edit: .edit("Only its owner can edit a playlist."),
            query: .query(access: \.$access, owner: \.$owner.$id)
        )
    }
}
