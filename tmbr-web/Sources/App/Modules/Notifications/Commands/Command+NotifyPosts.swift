import Foundation
import Vapor
import CoreWeb
import Fluent
import CoreAuth
import CoreTmbr

extension Command where Self == PlainCommand<Post, Void> {

    static func notification(
        permission: AuthPermissionResolver<Post>,
        content: CommandResolver<FilteredNotificationInput, Void>
    ) -> Self {
        PlainCommand { post in
            try await permission.grant(post)
            try await content(FilteredNotificationInput(
                notification: PushNotification(post: post),
                language: post.language.rawValue,
                contentType: "post",
                parentContentType: nil
            ))
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
                permission: request.permissions.notifications.post,
                content: request.commands.notifications.content
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
