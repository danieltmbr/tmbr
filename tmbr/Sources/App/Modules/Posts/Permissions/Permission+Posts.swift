import Foundation
import Core

extension PermissionScopes {
    var posts: PermissionScopes.Posts.Type { PermissionScopes.Posts.self }
}

extension PermissionScopes {
    struct Posts: PermissionScope, Sendable {
        
        let access: Permission<Post>
        
        let create: Permission<Void>
        
        let delete: Permission<Post>
        
        let edit: Permission<Post>
    }
}

extension Permission<Post> {
    
    static var accessPost: Permission<Post> {
        Permission<Post> { user, post in
            post.state == .published || post.author.id == user.id || user.role == .admin
        }
    }
    
    static var deletePost: Self {
        Permission<Post> { user, post in
            post.author.id == user.id || user.role == .admin
        }
    }
    
    static var editPost: Self {
        Permission<Post> { user, post in
            post.author.id == user.id || user.role == .admin
        }
    }
}

extension Permission<Void> {
    
    static var createPost: Self {
        Permission<Void> { user, _ in
            user.role == .author || user.role == .admin
        }
    }
}
