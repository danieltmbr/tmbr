import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<PostID, Void> {
    static func deletePost(
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Post>
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

extension CommandFactory<PostID, Void> {
    
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
