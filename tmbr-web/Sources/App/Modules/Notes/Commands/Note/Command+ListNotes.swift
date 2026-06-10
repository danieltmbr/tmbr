import Foundation
import Vapor
import Core
import Fluent
import TmbrCore

struct ListNotesInput: Sendable {
    let authorID: Int
    let since: Date?
    let before: Date?
    let limit: Int
}

extension Command where Self == PlainCommand<ListNotesInput, [Note]> {

    static func listNotes(database: Database) -> Self {
        PlainCommand { input in
            var query = Note.query(on: database)
                .filter(\.$author.$id == input.authorID)
                .sort(\.$createdAt, .descending)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image)
                }
                .with(\.$author)
                .with(\.$quotes)

            if let since = input.since {
                query = query.filter(\.$createdAt >= since)
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
            .listNotes(database: request.commandDB)
            .logged(name: "List notes", logger: request.logger)
        }
    }
}
