import Foundation
import Vapor
import WebCore
import Fluent
import WebAuth
import TmbrCore

extension Command where Self == PlainCommand<PreviewID, [Note]> {

    static func fetchNotesByAttachment(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { attachmentID in
            let query = Note
                .query(on: database)
                .filter(\.$attachment.$id == attachmentID)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image).with(\.$catalogueCategory)
                }
                .with(\.$author)
                .with(\.$quotes)
                .sort(\.$createdAt, .descending)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PreviewID, [Note]> {

    static var fetchNotesByAttachment: Self {
        CommandFactory { request in
            .fetchNotesByAttachment(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(name: "Fetch notes by attachment", logger: request.logger)
        }
    }
}
