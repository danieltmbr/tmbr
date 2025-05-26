import Fluent
import Vapor
import WebPush

func configureNotificationService(_ app: Application) throws {
    app.storage.set(
        NotificationServiceKey.self,
        to: try NotificationService(app: app)
    )
    
    let notificationsRoute = app.grouped("api", "notifications")
    let webPushRoute = notificationsRoute.grouped("web-push")

    // GET /api/notifications/web-push/vapid
    webPushRoute.get("vapid") { req async throws -> WebPushOptions in
        guard let service = req.application.notificationService else {
            throw Abort(.internalServerError, reason: "Notification service not configured")
        }
        return WebPushOptions(vapid: service.vapidKeyID)
    }
    
    // POST /api/notifications/web-push/subscription
    webPushRoute.post("subscription") { req async throws -> HTTPStatus in
        let subscription = try req.content.decode(WebPushSubscription.self)
        try await subscription.save(on: req.db)
        return .created
    }
    
    // DELETE /api/notifications/web-push/subscription
    webPushRoute.delete("subscription") { req async throws -> HTTPStatus in
        let subscription = try req.content.decode(WebPushSubscription.self)
        if let subscription = try await WebPushSubscription.query(on: req.db)
            .filter(\.$endpoint == subscription.endpoint)
            .first() {
            try await subscription.delete(on: req.db)
        }
        return .ok
    }
    
    // POST /api/notifications/notify/:postID
    notificationsRoute.get("notify", ":postID") { req async throws -> HTTPStatus in
        guard let key = Environment.get("NOTIFY_API_KEY"), !key.isEmpty,
              req.headers.bearerAuthorization?.token == key else {
            throw Abort(.unauthorized)
        }
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        Task.detached {
            let notificationService = app.notificationService
            try await notificationService?.notify(
                subscriptions: WebPushSubscription.query(on: req.db).all(),
                content: PushNotification(post: post)
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
