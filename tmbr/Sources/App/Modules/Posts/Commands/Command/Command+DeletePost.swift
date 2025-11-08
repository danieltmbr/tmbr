import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Core.Command where Self == PlainCommand<Post.IDValue, Void> {
    static func deletePost(
        database: Database,
        logger: Logger,
        permission: PermissionResolver<Post>
    ) -> Self {
        PlainCommand { postID in
            guard let post = try await Post.find(postID, on: database) else {
                throw Abort(.notFound, reason: "Post not found")
            }
            try await permission.grant(post)
            try await post.delete(on: database)
        }
    }
}

extension CommandFactory<Post.IDValue, Void> {
    
    static var deletePost: Self {
        CommandFactory { request in
            .deletePost(
                database: request.db,
                logger: request.logger,
                permission: request.permissions.posts.delete
            )
            .logged(name: "Delete Post", logger: request.logger)
        }
    }
}
