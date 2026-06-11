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

    static func listNotes(database: Database, permission: AuthPermissionResolver<Void>) -> Self {
        PlainCommand { input in
            let user = try await permission.grant()
            var query = Note.query(on: database)
                .filter(\.$author.$id == user.userID)
                .sort(\.$createdAt, .descending)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image)
                }
                .with(\.$author)
                .with(\.$quotes)

            if let since = input.since {
                query = query.filter(\.$createdAt > since)
            }
            if let before = input.before {
                query = query.filter(\.$createdAt < before)
            }

            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListNotesInput, [Note]> {

    static var listNotes: Self {
        CommandFactory { request in
            .listNotes(database: request.commandDB, permission: request.permissions.notes.list)
            .logged(name: "List notes", logger: request.logger)
        }
    }
}
