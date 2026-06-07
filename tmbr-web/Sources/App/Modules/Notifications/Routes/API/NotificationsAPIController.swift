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
        let contentTypes: [String]
    }

    private struct ContentOption: Content, Sendable {
        let value: String
        let label: String
        let icon: String
        var children: [ContentOption]?
    }

    private struct ContentOptionsResponse: Content, Sendable {
        let options: [ContentOption]
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

        // GET /api/notifications/web-push/content-options
        webPushRoute.get("content-options") { req async throws -> ContentOptionsResponse in
            let categories = try await CatalogueCategory.query(on: req.db)
                .filter(\.$kind ~~ [.collection, .catalogue])
                .all()

            // Collections (e.g. music) become Note children; standalone catalogue
            // items (book, movie, podcast) with no parent also become Note children.
            let noteChildren: [ContentOption] = categories
                .filter { $0.kind == .collection || ($0.kind == .catalogue && $0.parentSlug == nil) }
                .map { category in
                    ContentOption(
                        value: "note:\(category.slug)",
                        label: category.name,
                        icon: category.icon ?? category.slug
                    )
                }

            let options: [ContentOption] = [
                ContentOption(value: "post", label: "Posts", icon: "post"),
                ContentOption(value: "note", label: "Notes", icon: "note", children: noteChildren),
            ]
            return ContentOptionsResponse(options: options)
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
                sub.contentTypes = update.contentTypes.joined(separator: "|")
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
            let filteredSend = req.commands.notifications.filteredSend
            Task.detached {
                try await filteredSend(FilteredNotificationInput(
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
