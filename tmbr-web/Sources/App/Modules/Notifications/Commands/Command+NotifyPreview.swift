import Foundation
import Vapor
import WebCore
import Fluent
import WebAuth
import TmbrCore

struct NotifyPreviewInput: Sendable {
    let preview: Preview
    let language: String?
}

extension Command where Self == PlainCommand<NotifyPreviewInput, Void> {

    static func previewNotification(
        database: Database,
        permission: AuthPermissionResolver<Preview>,
        content: CommandResolver<FilteredNotificationInput, Void>
    ) -> Self {
        PlainCommand { input in
            try await permission.grant(input.preview)
            guard input.preview.parentAccess == .public else { return }
            try await input.preview.$catalogueCategory.load(on: database)
            let categorySlug = input.preview.catalogueCategory.map { "note:\($0.slug)" }
            let parentSlug = input.preview.catalogueCategory?.parentSlug.map { "note:\($0)" }
            try await content(FilteredNotificationInput(
                notification: try PushNotification(preview: input.preview),
                language: input.language,
                contentType: categorySlug,
                parentContentType: parentSlug
            ))
        }
    }
}

extension CommandFactory<NotifyPreviewInput, Void> {

    static var previewNotification: Self {
        CommandFactory { request in
            .previewNotification(
                database: request.commandDB,
                permission: request.permissions.notifications.preview,
                content: request.commands.notifications.content
            )
            .logged(name: "Send Preview Notification", logger: request.logger)
        }
    }
}
