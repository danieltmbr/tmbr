import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth
import TmbrCore

extension Command where Self == PlainCommand<NoteID, Note> {

    static func fetchNote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { noteID in
            let query = Note
                .query(on: database)
                .filter(\.$id == noteID)
                .with(\.$attachment) { $0.with(\.$image) }
                .with(\.$author)
                .with(\.$quotes)
            try await permission.grant(query)
            guard let note = try await query.first() else {
                throw Abort(.notFound)
            }
            return note
        }
    }
}

extension CommandFactory<NoteID, Note> {

    static var fetchNote: Self {
        CommandFactory { request in
            .fetchNote(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(name: "Fetch note", logger: request.logger)
        }
    }
}
