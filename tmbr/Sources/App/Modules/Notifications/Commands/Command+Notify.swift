import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<PushNotification, Void> {
    
    static func send(
        database: Database,
        permission: AuthPermissionResolver<PushNotification>,
        service: NotificationService?
    ) -> Self {
        PlainCommand { notification in
            try await permission.grant(notification)
            try await service?.notify(
                subscriptions: WebPushSubscription.query(on: database).all(),
                content: notification
            )
        }
    }
}

extension CommandFactory<PushNotification, Void> {
    
    static var send: Self {
        CommandFactory { request in
            .send(
                database: request.application.db,
                permission: request.permissions.notifications.generic,
                service: request.application.notificationService
            )
            .logged(name: "Send Notification", logger: request.logger)
        }
    }
}

