import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreatePostCommand: Command {
    
    typealias Input = PostPayload
    
    typealias Output = Post

    private let database: Database
    
    private let logger: Logger
    
    private let notify: CommandResolver<Post, Void>
    
    private let permission: AuthPermissionResolver<Void>

    init(
        database: Database,
        logger: Logger,
        notify: CommandResolver<Post, Void>,
        permission: AuthPermissionResolver<Void>
    ) {
        self.database = database
        self.logger = logger
        self.notify = notify
        self.permission = permission
    }

    func execute(_ payload: PostPayload) async throws -> Post {
        let user = try await permission.grant()
        try payload.validate()
        let post = Post(
            authorID: user.userID,
            content: payload.body ?? "",
            state: payload.state,
            title: payload.title
        )
        try await post.save(on: database)
        notify(about: post)
        return post
    }
    
    private func notify(about post: Post) {
        guard post.state == .published else { return }
        Task.detached {
            try await notify(post)
        }
    }
}

extension CommandFactory<PostPayload, Post> {

    static var createPost: Self {
        CommandFactory { request in
            CreatePostCommand(
                database: request.application.db,
                logger: request.application.logger,
                notify: request.commands.notifications.post,
                permission: request.permissions.posts.create
            )
            .logged(logger: request.logger)
        }
    }
}
