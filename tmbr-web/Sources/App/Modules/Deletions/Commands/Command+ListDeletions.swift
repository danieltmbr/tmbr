import Foundation
import Fluent
import Core
import TmbrCore

struct ListDeletionsInput: Sendable {
    let since: Date?
    let userID: UserID
}

extension Command where Self == PlainCommand<ListDeletionsInput, [Deletion]> {

    static func listDeletions(database: Database) -> Self {
        PlainCommand { input in
            var query = Deletion.query(on: database)
                .group(.or) {
                    $0.filter(\.$ownerID == input.userID)
                    $0.filter(\.$access == Access.public.rawValue)
                }
                .sort(\.$deletedAt, .ascending)
            if let since = input.since {
                query = query.filter(\.$deletedAt > since)
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
