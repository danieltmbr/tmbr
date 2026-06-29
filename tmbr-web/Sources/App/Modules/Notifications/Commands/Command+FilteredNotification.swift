import Foundation
import Vapor
import WebCore
import Fluent

struct FilteredNotificationInput: Sendable {
    /// The notification payload to deliver.
    let notification: PushNotification
    /// Raw language code to filter on (e.g. "en"). Nil = no language filter.
    let language: String?
    /// Content-type token for this specific item (e.g. "note:song"). Nil = no content-type filter.
    let contentType: String?
    /// Parent content-type token (e.g. "note:music" when contentType is "note:song"). Nil if no parent.
    let parentContentType: String?
}

extension Command where Self == PlainCommand<FilteredNotificationInput, Void> {

    static func content(
        database: Database,
        service: NotificationService?
    ) -> Self {
        PlainCommand { input in
            let allSubs = try await WebPushSubscription.query(on: database).all()
            let subs = allSubs.filter { sub in
                // Language filter
                if let lang = input.language {
                    guard sub.languages.isEmpty
                        || sub.languages.split(separator: "|").contains(Substring(lang))
                    else { return false }
                }
                // Content-type filter
                if let ct = input.contentType {
                    let types = sub.contentTypes.split(separator: "|").map(String.init)
                    guard sub.contentTypes.isEmpty
                        || types.contains(ct)
                        || input.parentContentType.map({ types.contains($0) }) ?? false
                        || types.contains(where: { ct.hasPrefix($0 + ":") })
                    else { return false }
                }
                return true
            }
            await service?.notify(subscriptions: subs, content: input.notification)
        }
    }
}

extension CommandFactory<FilteredNotificationInput, Void> {

    static var content: Self {
        CommandFactory { request in
            .content(
                database: request.commandDB,
                service: request.application.notificationService
            )
            .logged(name: "Send Content Notification", logger: request.logger)
        }
    }
}
