import Foundation
import Fluent
import Core

extension Command where Self == PlainCommand<Date?, [Deletion]> {

    static func listDeletions(database: Database) -> Self {
        PlainCommand { since in
            var query = Deletion.query(on: database).sort(\.$deletedAt, .ascending)
            if let since {
                query = query.filter(\.$deletedAt > since)
            }
            return try await query.all()
        }
    }
}

extension CommandFactory<Date?, [Deletion]> {

    static var listDeletions: Self {
        CommandFactory { request in
            .listDeletions(database: request.commandDB)
            .logged(name: "List deletions", logger: request.logger)
        }
    }
}
