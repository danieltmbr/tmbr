import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Core.Command where Self == PlainCommand<Post.IDValue, Post> {
    
    static func fetchPost(
        database: Database,
        permission: BasePermissionResolver<Post>
    ) -> Self {
        PlainCommand { postID in
            guard let post = try await Post.find(postID, on: database) else {
                throw Abort(.notFound, reason: "Post not found")
            }
            try await permission.grant(post)
            return post
        }
    }
}

extension CommandFactory<Post.IDValue, Post> {
    
    static var fetchPost: Self {
        CommandFactory { request in
            .fetchPost(
                database: request.db,
                permission: request.permissions.posts.access
            )
            .logged(name: "Fetch Post", logger: request.logger)
        }
    }
}
