import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct PreviewQueryInput: Sendable {

    let term: String?

    let categoryIDs: Set<Int>?

    init(
        term: String? = nil,
        categoryIDs: Set<Int>? = nil
    ) {
        self.term = term
        self.categoryIDs = categoryIDs
    }
}

extension Command where Self == PlainCommand<PreviewQueryInput, [Preview]> {

    static func listPreviews(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>
    ) -> Self {
        PlainCommand { input in
            let query = Preview.query(on: database)
                .with(\.$parentOwner)
                .sort(\.$createdAt, .descending)
                .with(\.$image)
                .with(\.$catalogueCategory)

            if let categoryIDs = input.categoryIDs {
                query.filter(\.$catalogueCategory.$id ~~ categoryIDs)
            }
            if let term = input.term, !term.isEmpty {
                query.group(.or) { group in
                    group.filter(\.$primaryInfo, .custom("ILIKE"), "%\(term)%")
                    group.filter(\.$secondaryInfo, .custom("ILIKE"), "%\(term)%")
                }
            }
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PreviewQueryInput, [Preview]> {

    static var listPreviews: Self {
        CommandFactory { request in
            .listPreviews(
                database: request.commandDB,
                permission: request.permissions.previews.query
            )
            .logged(
                name: "List previews",
                logger: request.logger
            )
        }
    }
}
