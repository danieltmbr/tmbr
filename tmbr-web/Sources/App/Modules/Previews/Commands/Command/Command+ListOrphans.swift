import Foundation
import Core
import Fluent
import AuthKit
import TmbrCore

struct ListOrphansInput: Sendable {
    let since: Date?
    let before: Date?
    let limit: Int

    init(since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.since = since
        self.before = before
        self.limit = limit
    }
}

extension Command where Self == PlainCommand<ListOrphansInput, [Preview]> {

    static func listOrphans(database: Database, permission: BasePermissionResolver<QueryBuilder<Preview>>) -> Self {
        PlainCommand { input in
            let query = Preview.query(on: database)
                .join(CatalogueCategory.self, on: \Preview.$catalogueCategory.$id == \CatalogueCategory.$id)
                .filter(CatalogueCategory.self, \.$kind == .orphan)
                .sort(\.$createdAt, .descending)
                .with(\.$image)
                .with(\.$catalogueCategory)
            if let since = input.since { query.filter(\.$createdAt > since) }
            if let before = input.before { query.filter(\.$createdAt < before) }
            try await permission.grant(query)
            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListOrphansInput, [Preview]> {

    static var listOrphans: Self {
        CommandFactory { request in
            .listOrphans(database: request.commandDB, permission: request.permissions.previews.query)
            .logged(name: "List orphans", logger: request.logger)
        }
    }
}
