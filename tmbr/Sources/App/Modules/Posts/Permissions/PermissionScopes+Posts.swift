import AuthKit

extension PermissionScopes {
    var posts: PermissionScopes.Posts.Type { PermissionScopes.Posts.self }
}

extension PermissionScopes {
    struct Posts: PermissionScope, Sendable {
        
        let access: Permission<Post>
        
        let create: AuthenticatingPermission<Void>
        
        let delete: AuthenticatingPermission<Post>
        
        let drafts: AuthenticatingPermission<Void>
        
        let edit: AuthenticatingPermission<Post>
        
        init(
            access: Permission<Post> = .accessPost,
            create: AuthenticatingPermission<Void> = .createPost,
            delete: AuthenticatingPermission<Post> = .deletePost,
            drafts: AuthenticatingPermission<Void> = .listDrafts,
            edit: AuthenticatingPermission<Post> = .editPost
        ) {
            self.access = access
            self.create = create
            self.delete = delete
            self.drafts = drafts
            self.edit = edit
        }
    }
}
