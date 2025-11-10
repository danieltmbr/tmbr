import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreatePostCommand: Core.Command {
    
    typealias Input = Post
    
    typealias Output = Post

    private let database: Database
    
    private let logger: Logger
    
    private let notificationService: NotificationService?
    
    private let permission: AuthPermissionResolver<Void>

    init(
        database: Database,
        logger: Logger,
        notificationService: NotificationService?,
        permission: AuthPermissionResolver<Void>
    ) {
        self.database = database
        self.logger = logger
        self.notificationService = notificationService
        self.permission = permission
    }

    func execute(_ post: Post) async throws -> Post {
        let user = try await permission.grant()
        post.$author.id = user.userID
        try await post.save(on: database)
        sendNotification(for: post)
        return post
    }
    
    private func sendNotification(for post: Post) {
        Task.detached {
            try await notificationService?.notify(
                subscriptions: WebPushSubscription.query(on: database).all(),
                content: PushNotification(post: post)
            )
        }
    }
}

extension CommandFactory<Post, Post> {

    static var createPost: Self {
        CommandFactory { request in
            CreatePostCommand(
                database: request.application.db,
                logger: request.application.logger,
                notificationService: request.application.notificationService,
                permission: request.permissions.posts.create
            )
            .logged(logger: request.logger)
        }
    }
}
