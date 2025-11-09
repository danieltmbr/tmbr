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
    
    typealias Input = FetchPostParameters
    
    typealias Output = Post
    
    private let database: Database
    
    private let logger: Logger
        
    private let readPermission: VoidPermissionResolver<Post>
    
    private let writePermission: VoidPermissionResolver<Post>
    
    init(
        database: Database,
        logger: Logger,
        readPermission: VoidPermissionResolver<Post>,
        writePermission: VoidPermissionResolver<Post>
    ) {
        self.database = database
        self.logger = logger
        self.readPermission = readPermission
        self.writePermission = writePermission
    }
    
    func execute(_ params: FetchPostParameters) async throws -> Post {
        guard let post = try await Post.find(params.postID, on: database) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        switch params.reason {
        case .read: try await readPermission.grant(post)
        case .write: try await writePermission.grant(post)
        }
        return post
    }
}

extension CommandFactory<FetchPostParameters, Post> {
    
    static var fetchPost: Self {
        CommandFactory { request in
            FetchPostCommand(
                database: request.application.db,
                logger: request.application.logger,
                readPermission: request.permissions.posts.access.ereaseOutput(),
                writePermission: request.permissions.posts.edit.ereaseOutput()
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
