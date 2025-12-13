import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditPostCommand: Command {
    
    private let database: Database
    
    private let logger: Logger
    
    private let notify: CommandResolver<Post, Void>

    private let permission: AuthPermissionResolver<Post>
    
    init(
        database: Database,
        logger: Logger,
        notify: CommandResolver<Post, Void>,
        permission: AuthPermissionResolver<Post>
    ) {
        self.database = database
        self.logger = logger
        self.notify = notify
        self.permission = permission
    }
    
    func execute(_ payload: EditPostPayload) async throws -> Post {
        guard let post = try await Post.find(payload.id, on: database) else {
            throw Abort(.notFound)
        }
        try await permission.grant(post)
        try payload.validate()
        post.title = payload.title
        post.content = payload.body ?? ""
        post.state = payload.state
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

extension CommandFactory<EditPostPayload, Post> {
    
    static var editPost: Self {
        CommandFactory { request in
            EditPostCommand(
                database: request.commandDB,
                logger: request.application.logger,
                notify: request.commands.notifications.post,
                permission: request.permissions.posts.edit
            )
            .logged(logger: request.logger)
        }
    }
}
