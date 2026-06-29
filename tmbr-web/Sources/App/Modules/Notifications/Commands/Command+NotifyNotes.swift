import Foundation
import Vapor
import WebCore
import Fluent
import WebAuth
import TmbrCore

extension Command where Self == PlainCommand<Note, Void> {

    static func noteNotification(
        database: Database,
        permission: AuthPermissionResolver<Note>,
        content: CommandResolver<FilteredNotificationInput, Void>
    ) -> Self {
        PlainCommand { note in
            try await permission.grant(note)
            guard let preview = try await Preview.find(note.$attachment.id, on: database) else { return }
            try await preview.$catalogueCategory.load(on: database)
            let categorySlug    = preview.catalogueCategory.map { "note:\($0.slug)" }
            let parentSlug      = preview.catalogueCategory?.parentSlug.map { "note:\($0)" }
            try await content(FilteredNotificationInput(
                notification: PushNotification(note: note, preview: preview),
                language: note.language.rawValue,
                contentType: categorySlug,
                parentContentType: parentSlug
            ))
        }
    }
}

extension CommandFactory<Note, Void> {

    static var noteNotification: Self {
        CommandFactory { request in
            .noteNotification(
                database: request.commandDB,
                permission: request.permissions.notifications.note,
                content: request.commands.notifications.content
            )
            .logged(name: "Send Note Notification", logger: request.logger)
        }
    }
}
