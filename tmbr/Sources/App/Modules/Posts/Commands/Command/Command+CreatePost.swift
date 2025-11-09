import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Core.Command where Self == PlainCommand<Post, Post> {
    
    static func createPost(
        database: Database,
        logger: Logger,
        notificationService: NotificationService?,
        permission: AuthPermissionResolver<Void>
    ) -> Self {
        PlainCommand { post in
            let user = try await permission.grant()
            post.$author.id = user.userID
            try await post.save(on: database)
            
            Task.detached {
                try await notificationService?.notify(
                    subscriptions: WebPushSubscription.query(on: database).all(),
                    content: PushNotification(post: post)
                )
            }
            
            return post
        }
    }
}

extension CommandFactory<Post, Post> {
    
    static var createPost: Self {
        CommandFactory { request in
            .createPost(
                database: request.application.db,
                logger: request.application.logger,
                // TODO: Inject noty service into services storage
                notificationService: request.application.notificationService,
                permission: request.permissions.posts.create
            )
            .logged(name: "Create Post Command", logger: request.logger)
        }
    }
}


