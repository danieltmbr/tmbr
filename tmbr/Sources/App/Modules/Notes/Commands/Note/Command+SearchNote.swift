import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<NoteQueryPayload, [Note]> {
    static func searchNote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { input in
            guard let term = input.term?.trimmed, !term.isEmpty else {
                return []
            }
            let query = Note
                .query(on: database)
                .with(\.$attachment) { $0.with(\.$image) }
                .with(\.$author)
                .with(\.$quotes)
                .filter(Preview.self, \.$parentType ~~? input.types)
                .group(.or) { group in
                    let sql = "body ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                    group.filter(.sql(unsafeRaw: sql))
                }
                .sort(\Note.$createdAt, .descending)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<NoteQueryPayload, [Note]> {
    
    static var searchNote: Self {
        CommandFactory { request in
            .searchNote(
                database: request.application.db,
                permission: request.permissions.notes.query
            )
            .logged(
                name: "Search Note",
                logger: request.logger
            )
        }
    }
}
