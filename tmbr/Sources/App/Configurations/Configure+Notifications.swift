import Fluent
import Vapor
import WebPush

func configureNotificationService(_ app: Application) throws {
    app.storage.set(
        NotificationServiceKey.self,
        to: try NotificationService(app: app)
    )
    
    let notificationsRoute = app.grouped("api", "notifications")

    // GET /api/notifications/vapid
    notificationsRoute.get("vapid") { req async throws -> WebPushOptions in
        guard let service = req.application.notificationService else {
            throw Abort(.internalServerError, reason: "Notification service not configured")
        }
        return WebPushOptions(vapid: service.vapidKeyID)
    }
    
    // POST /api/notifications/subscription
    notificationsRoute.post("subscription") { req async throws -> HTTPStatus in
        print(req.content)
        let subscription = try req.content.decode(Subscription.self)
        try await subscription.save(on: req.db)
        return .created
    }
    
    // DELETE /api/notifications/subscription
    notificationsRoute.delete("subscription") { req async throws -> HTTPStatus in
        let subscription = try req.content.decode(Subscription.self)
        if let subscription = try await Subscription.query(on: req.db)
            .filter(\.$endpoint == subscription.endpoint)
            .first() {
            try await subscription.delete(on: req.db)
        }
        return .ok
    }
    
    // POST /api/notifications/notify
    notificationsRoute.get("notify") { req async throws -> HTTPStatus in
        Task.detached {
            let notificationService = app.notificationService
            try await notificationService?.notify(
                subscriptions: Subscription.query(on: req.db).all(),
                content: PushNotification(
                    title: "New post",
                    body: "Double standard",
                    url: URL(string: "https://tmbr.me/posts/6")!
                )
            )
        }
        return .ok
    }
}

/// A wrapper for the VAPID key that Vapor can encode.
private struct WebPushOptions: Content, Hashable, Sendable {
    var vapid: VAPID.Key.ID
}

private struct NotificationServiceKey: StorageKey {
    typealias Value = NotificationService
}

extension Application {
    var notificationService: NotificationService? {
        storage[NotificationServiceKey.self]
    }
}
