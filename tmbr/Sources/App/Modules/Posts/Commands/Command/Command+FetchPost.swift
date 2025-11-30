import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchPostCommand: Command {
    
    typealias PermissionInput = (post: Post, reason: FetchReason)
    
    typealias Input = FetchParameters<PostID>
    
    typealias Output = Post
    
    private let database: Database
    
    private let logger: Logger
        
    private let permission: ErasedPermissionResolver<PermissionInput>

    init(
        database: Database,
        logger: Logger,
        permission: ErasedPermissionResolver<PermissionInput>
    ) {
        self.database = database
        self.logger = logger
        self.permission = permission
    }
    
    init(
        database: Database,
        logger: Logger,
        readPermission: BasePermissionResolver<Post>,
        writePermission: AuthPermissionResolver<Post>
    ) {
        self.init(
            database: database,
            logger: logger,
            permission: ErasedPermissionResolver(input: \.post, condition: \.reason) { reason in
                switch reason {
                case .read: readPermission.ereaseOutput()
                case .write: writePermission.ereaseOutput()
                }
            }
        )
    }
    
    func execute(_ params: FetchParameters<PostID>) async throws -> Post {
        guard let post = try await Post.find(params.itemID, on: database) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        try await permission.grant((post, params.reason))
        try await post.$attachment.load(on: database)
        return post
    }
}

extension CommandFactory<FetchParameters<PostID>, Post> {
    
    static var fetchPost: Self {
        CommandFactory { request in
            FetchPostCommand(
                database: request.application.db,
                logger: request.application.logger,
                readPermission: request.permissions.posts.access,
                writePermission: request.permissions.posts.edit
            )
            .logged(logger: request.logger)
        }
    }
}
