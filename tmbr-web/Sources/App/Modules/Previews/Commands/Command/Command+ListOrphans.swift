import Foundation
import Vapor
import Core
import Fluent
import TmbrCore

struct ListOrphansInput: Sendable {
    let ownerID: Int
    let since: Date?
    let before: Date?
    let limit: Int

    init(ownerID: Int, since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.ownerID = ownerID
        self.since = since
        self.before = before
        self.limit = limit
    }
}

extension Command where Self == PlainCommand<ListOrphansInput, [Preview]> {

    static func listOrphans(database: Database) -> Self {
        PlainCommand { input in
            var query = Preview.query(on: database)
                .filter(\.$parentOwner.$id == input.ownerID)
                .join(CatalogueCategory.self, on: \Preview.$catalogueCategory.$id == \CatalogueCategory.$id)
                .filter(CatalogueCategory.self, \.$kind == .orphan)
                .sort(\.$createdAt, .descending)
                .with(\.$image)
                .with(\.$catalogueCategory)

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

extension CommandFactory<ListOrphansInput, [Preview]> {

    static var listOrphans: Self {
        CommandFactory { request in
            .listOrphans(database: request.commandDB)
            .logged(name: "List orphans", logger: request.logger)
        }
    }
}
