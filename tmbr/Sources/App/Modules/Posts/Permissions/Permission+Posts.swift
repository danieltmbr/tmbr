import Foundation
import Core
import AuthKit

extension Permission<Post> {
    
    static var accessPost: Permission<Post> {
        Permission<Post> { user, post in
            post.state == .published || post.author.id == user.userID || user.role == .admin
        }
    }
    
    static var deletePost: Self {
        Permission<Post> { user, post in
            post.author.id == user.userID || user.role == .admin
        }
    }
    
    static var editPost: Self {
        Permission<Post> { user, post in
            post.author.id == user.userID || user.role == .admin
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
