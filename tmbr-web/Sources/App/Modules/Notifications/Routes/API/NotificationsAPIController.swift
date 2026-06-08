import Vapor
import Fluent
import WebPush

struct NotificationsAPIController: RouteCollection {

    /// A wrapper for the VAPID key that Vapor can encode.
    private struct WebPushOptions: Content, Hashable, Sendable {
        var vapid: VAPID.Key.ID
    }

    private struct PreferencesUpdate: Content {
        let endpoint: String
        let languages: [String]
        let contentTypes: [String]?
    }

    func boot(routes: RoutesBuilder) throws {

        let notificationsRoute = routes.grouped("api", "notifications")
        let webPushRoute = notificationsRoute.grouped("web-push")

        // GET /api/notifications/web-push/vapid
        webPushRoute.get("vapid") { req async throws -> WebPushOptions in
            guard let service = req.application.notificationService else {
                throw Abort(.serviceUnavailable, reason: "Notification service not configured")
            }
            return WebPushOptions(vapid: service.vapidKeyID)
        }

        // POST /api/notifications/web-push/subscription
        webPushRoute.post("subscription") { req async throws -> HTTPStatus in
            let subscription = try req.content.decode(WebPushSubscription.self)
            try await subscription.save(on: req.db)
            return .created
        }

        // PATCH /api/notifications/web-push/subscription
        webPushRoute.patch("subscription") { req async throws -> HTTPStatus in
            let update = try req.content.decode(PreferencesUpdate.self)
            if let sub = try await WebPushSubscription.query(on: req.db)
                .filter(\.$endpoint == update.endpoint)
                .first() {
                sub.languages = update.languages.joined(separator: "|")
                if let contentTypes = update.contentTypes {
                    sub.contentTypes = contentTypes.joined(separator: "|")
                }
                try await sub.save(on: req.db)
            }
            return .ok
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

        // GET /api/notifications/notify/:postID  (admin, bearer-token gated)
        notificationsRoute.get("notify", ":postID") { req async throws -> HTTPStatus in
            guard let key = Environment.webPush.notifyApiKey, !key.isEmpty,
                  req.headers.bearerAuthorization?.token == key else {
                throw Abort(.unauthorized)
            }
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid post ID")
            }
            guard let post = try await Post.find(postID, on: req.db) else {
                throw Abort(.notFound, reason: "Post not found")
            }
            let content = req.commands.notifications.content
            Task.detached {
                try? await content(FilteredNotificationInput(
                    notification: PushNotification(post: post),
                    language: post.language.rawValue,
                    contentType: "post",
                    parentContentType: nil
                ))
            }
            return .ok
        }
    }

}
