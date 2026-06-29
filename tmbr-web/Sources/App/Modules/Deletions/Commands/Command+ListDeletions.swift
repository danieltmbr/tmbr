import Foundation
import Fluent
import WebCore
import TmbrCore

struct ListDeletionsInput: Sendable {
    let since: Date?
    let userID: UserID?
}

extension Command where Self == PlainCommand<ListDeletionsInput, [Deletion]> {

    static func listDeletions(database: Database) -> Self {
        PlainCommand { input in
            var query = Deletion.query(on: database).sort(\.$deletedAt, .ascending)
            if let since = input.since {
                query = query.filter(\.$deletedAt > since)
            }
            if let userID = input.userID {
                query = query.group(.or) {
                    $0.filter(\.$ownerID == userID)
                    $0.filter(\.$access == Access.public.rawValue)
                }
            } else {
                query = query.filter(\.$access == Access.public.rawValue)
            }
            return try await query.all()
        }
    }
}

extension CommandFactory<ListDeletionsInput, [Deletion]> {

    static var listDeletions: Self {
        CommandFactory { request in
            .listDeletions(database: request.commandDB)
            .logged(name: "List deletions", logger: request.logger)
        }
    }
}
