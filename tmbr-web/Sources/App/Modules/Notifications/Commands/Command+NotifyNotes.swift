import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

extension Command where Self == PlainCommand<Note, Void> {

    static func noteNotification(
        database: Database,
        permission: AuthPermissionResolver<Note>,
        filteredSend: CommandResolver<FilteredNotificationInput, Void>
    ) -> Self {
        PlainCommand { note in
            try await permission.grant(note)
            guard let preview = try await Preview.find(note.$attachment.id, on: database) else { return }
            try await preview.$catalogueCategory.load(on: database)
            let categorySlug    = preview.catalogueCategory.map { "note:\($0.slug)" }
            let parentSlug      = preview.catalogueCategory?.parentSlug.map { "note:\($0)" }
            try await filteredSend(FilteredNotificationInput(
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
                filteredSend: request.commands.notifications.filteredSend
            )
            .logged(name: "Send Note Notification", logger: request.logger)
        }
    }
}
