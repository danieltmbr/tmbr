import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<Post, Void> {
    
    static func notification(
        database: Database,
        permission: AuthPermissionResolver<Post>,
        service: NotificationService?
    ) -> Self {
        PlainCommand { post in
            try await permission.grant(post)
            try await service?.notify(
                subscriptions: WebPushSubscription.query(on: database).all(),
                content: PushNotification(post: post)
            )
        }
    }
}

extension Command where Self == PlainCommand<PostID, Void> {
    
    static func notificationByID<O>(
        database: Database,
        notify: CommandResolver<Post, O>
    ) -> Self {
        PlainCommand { postID in
            guard let post = try await Post.find(postID, on: database) else {
                throw Abort(.notFound, reason: "Post (id: \(postID)) not found. Notifications were not sent.")
            }
            _ = try await notify(post)
        }
    }
}

extension CommandFactory<Post, Void> {
    
    static var postNotification: Self {
        CommandFactory { request in
            .notification(
                database: request.commandDB,
                permission: request.permissions.notifications.post,
                service: request.application.notificationService
            )
            .logged(name: "Send Post Notification", logger: request.logger)
        }
    }
}

extension CommandFactory<PostID, Void> {
    
    static var postNotificationByID: Self {
        CommandFactory { request in
            .notificationByID(
                database: request.commandDB,
                notify: request.commands.notifications.post
            )
        }
    }
}
