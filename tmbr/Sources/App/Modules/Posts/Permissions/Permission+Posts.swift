import Foundation
import Core
import AuthKit

extension Permission<Post> {
    
    static var accessPost: Permission<Post> {
        Permission<Post>(
            "This post is not published yet. Only its author can see a draft post."
        ) { user, post in
            post.state == .published || post.author.id == user.userID || user.role == .admin
        }
    }
    
    static var deletePost: Self {
        Permission<Post>(
            "Only its author can delete a post."
        ) { user, post in
            post.author.id == user.userID || user.role == .admin
        }
    }
    
    static var editPost: Self {
        Permission<Post>(
            "Only its author can edit a post."
        ) { user, post in
            post.author.id == user.userID || user.role == .admin
        }
    }
}

extension Permission<Void> {
    
    static var createPost: Self {
        Permission<Void>(
            "Only authors can create posts."
        ) { user, _ in
            user.role == .author || user.role == .admin
        }
    }
    
    static var listDrafts: Self {
        Permission<Void>()
    }
}
