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
    
    private let notify: CommandResolver<PushNotification, Void>
    
    private let permission: AuthPermissionResolver<Void>

    init(
        database: Database,
        logger: Logger,
        notify: CommandResolver<PushNotification, Void>,
        permission: AuthPermissionResolver<Void>
    ) {
        self.database = database
        self.logger = logger
        self.notify = notify
        self.permission = permission
    }

    func execute(_ payload: PostPayload) async throws -> Post {
        let user = try await permission.grant()
        
        // TODO: Validation
        guard !payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Title is required.")
        }
        if payload.state == .published {
            let body = payload.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if body.isEmpty {
                throw Abort(.badRequest, reason: "Sorry, can't publich an empty post.")
            }
        }
        
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
            try await notify(PushNotification(post: post))
        }
    }
}

extension CommandFactory<PostPayload, Post> {

    static var createPost: Self {
        CommandFactory { request in
            CreatePostCommand(
                database: request.application.db,
                logger: request.application.logger,
                notify: request.commands.notifications.send,
                permission: request.permissions.posts.create
            )
            .logged(logger: request.logger)
        }
    }
}
