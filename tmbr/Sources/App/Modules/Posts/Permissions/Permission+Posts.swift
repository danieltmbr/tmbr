import Foundation
import Core
import AuthKit
import Vapor

extension Permission<Post> {
    static var accessPost: Permission<Post> {
        Permission<Post>(
            "This post is not published yet. Only its author can see a draft post."
        ) { user, post in
            if post.state == .published { return true }
            guard let user else { throw Abort(.unauthorized) }
            return post.$author.id == user.userID || user.role == .admin
        }
    }
}

extension AuthenticatingPermission<Post> {
    
    static var deletePost: Self {
        AuthenticatingPermission<Post>(
            "Only its author can delete a post."
        ) { user, post in
            post.$author.id == user.userID || user.role == .admin
        }
    }
    
    static var editPost: Self {
        AuthenticatingPermission<Post>(
            "Only its author can edit a post."
        ) { user, post in
            post.$author.id == user.userID || user.role == .admin
        }
    }
}

extension AuthenticatingPermission<Void> {
    
    static var createPost: Self {
        AuthenticatingPermission<Void>(
            "Only authors can create posts."
        ) { user, _ in
            user.role == .author || user.role == .admin
        }
    }
    
    static var listDrafts: Self {
        AuthenticatingPermission<Void>()
    }
}
