import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct QueryNotesInput: Sendable {
    let ownerID: Int
    
    let ownerType: String
}

extension Command where Self == PlainCommand<QueryNotesInput, [Note]> {
    
    static func queryNotes(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { input in
            let query = Note
                .query(on: database)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image)
                }
                .filter(Preview.self, \.$parentType == input.ownerType)
                .filter(Preview.self, \.$parentID == input.ownerID)
                .sort(\Note.$createdAt, .descending)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<QueryNotesInput, [Note]> {
    
    static var queryNotes: Self {
        CommandFactory { request in
            .queryNotes(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(
                name: "Query notes",
                logger: request.logger
            )
        }
    }
}

extension CommandResolver where Input == QueryNotesInput {
    
    func callAsFunction(id: Int, of type: String) async throws -> Output {
        try await callAsFunction(QueryNotesInput(
            ownerID: id,
            ownerType: type
        ))
    }
    
    func callAsFunction<Item: Previewable>(for item: Item) async throws -> Output {
        try await callAsFunction(id: item.requireID(), of: Item.previewType)
    }
}
