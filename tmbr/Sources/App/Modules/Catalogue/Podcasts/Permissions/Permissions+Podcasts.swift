import AuthKit
import Fluent

extension PermissionScopes {
    var podcasts: PreviewablePermissionScope<Podcast>.Type { PreviewablePermissionScope<Podcast>.self }
}

extension PreviewablePermissionScope<Podcast> {
    static var podcasts: Self {
        PreviewablePermissionScope(
            access: .access("This podcast is private."),
            create: .create("You don't have permission to create a podcast."),
            delete: .delete("Only its owner can delete a podcast."),
            edit: .edit("Only its owner can edit a podcast."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}
