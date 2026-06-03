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
                .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                .with(\.$attachment) { $0.with(\.$image) }
                .with(\.$author)
                .with(\.$quotes)
                .group(.or) { group in
                    let sql = "body ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                    group.filter(.sql(unsafeRaw: sql))
                }
                .sort(\Note.$createdAt, .descending)
            switch (input.types, input.categories) {
            case (let types?, let cats?):
                query.group(.or) { group in
                    group.filter(Preview.self, \.$parentType ~~ types)
                    group.group(.and) { inner in
                        inner.filter(Preview.self, \.$parentType == nil)
                        inner.filter(Preview.self, \.$category ~~ cats)
                    }
                }
            case (let types?, nil):
                query.filter(Preview.self, \.$parentType ~~ types)
            case (nil, let cats?):
                query.filter(Preview.self, \.$parentType == nil)
                query.filter(Preview.self, \.$category ~~ cats)
            case (nil, nil):
                break
            }
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<NoteQueryPayload, [Note]> {
    
    static var searchNote: Self {
        CommandFactory { request in
            .searchNote(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(
                name: "Search Note",
                logger: request.logger
            )
        }
    }
}
