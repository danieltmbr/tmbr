import AuthKit

extension PermissionScopes {
    var posts: PermissionScopes.Posts.Type { PermissionScopes.Posts.self }
}

extension PermissionScopes {
    struct Posts: PermissionScope, Sendable {
        
        let access: Permission<Post>
        
        let create: Permission<Void>
        
        let delete: Permission<Post>
        
        let drafts: Permission<Void>
        
        let edit: Permission<Post>
        
        init(
            access: Permission<Post> = .accessPost,
            create: Permission<Void> = .createPost,
            delete: Permission<Post> = .deletePost,
            drafts: Permission<Void> = .listDrafts,
            edit: Permission<Post> = .editPost
        ) {
            self.access = access
            self.create = create
            self.delete = delete
            self.drafts = drafts
            self.edit = edit
        }
    }
}
