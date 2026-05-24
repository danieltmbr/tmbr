import AuthKit

extension PermissionScopes {
    var posts: PermissionScopes.Posts.Type { PermissionScopes.Posts.self }
}

extension PermissionScopes {
    struct Posts: PermissionScope, Sendable {
        
        let access: Permission<Post>
        
        let create: AuthPermission<Void>
        
        let delete: AuthPermission<Post>
        
        let drafts: AuthPermission<Void>
        
        let edit: AuthPermission<Post>
        
        init(
            access: Permission<Post> = .accessPost,
            create: AuthPermission<Void> = .createPost,
            delete: AuthPermission<Post> = .deletePost,
            drafts: AuthPermission<Void> = .listDrafts,
            edit: AuthPermission<Post> = .editPost
        ) {
            self.access = access
            self.create = create
            self.delete = delete
            self.drafts = drafts
            self.edit = edit
        }
    }
}
