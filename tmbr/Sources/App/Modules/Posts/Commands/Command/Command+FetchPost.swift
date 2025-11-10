import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

public enum FetchReason: Sendable {
    case read
    case write
}

public struct FetchPostParameters: Sendable {
    fileprivate let postID: PostID
    
    fileprivate let reason: FetchReason
    
    init(postID: PostID, reason: FetchReason) {
        self.postID = postID
        self.reason = reason
    }
}

struct FetchPostCommand: Command {
    
    typealias PermissionInput = (post: Post, reason: FetchReason)
    
    typealias Input = FetchPostParameters
    
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
    
    func execute(_ params: FetchPostParameters) async throws -> Post {
        guard let post = try await Post.find(params.postID, on: database) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        try await permission.grant((post, params.reason))
        return post
    }
}

extension CommandFactory<FetchPostParameters, Post> {
    
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

extension CommandResolver<FetchPostParameters, Post> {
    func callAsFunction(_ postID: PostID, for reason: FetchReason) async throws -> Post {
        try await callAsFunction(FetchPostParameters(postID: postID, reason: reason))
    }
}
