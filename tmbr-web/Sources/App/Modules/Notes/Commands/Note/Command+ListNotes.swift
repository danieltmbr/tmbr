import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct ListNotesInput: Sendable {
    let since: Date?
    let before: Date?
    let limit: Int
}

extension Command where Self == PlainCommand<ListNotesInput, [Note]> {

    static func listNotes(database: Database, permission: BasePermissionResolver<QueryBuilder<Note>>) -> Self {
        PlainCommand { input in
            let query = Note.query(on: database)
                .sort(\.$createdAt, .descending)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image)
                }
                .with(\.$author)
                .with(\.$quotes)
            if let since = input.since { query.filter(\.$createdAt > since) }
            if let before = input.before { query.filter(\.$createdAt < before) }
            try await permission.grant(query)
            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListNotesInput, [Note]> {

    static var listNotes: Self {
        CommandFactory { request in
            .listNotes(database: request.commandDB, permission: request.permissions.notes.query)
            .logged(name: "List notes", logger: request.logger)
        }
    }
}
