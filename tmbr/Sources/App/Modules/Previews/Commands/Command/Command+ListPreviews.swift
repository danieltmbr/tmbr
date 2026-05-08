import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct PreviewQueryInput: Sendable {
    let types: Set<String>?
    let term: String?

    init(types: Set<String>? = nil, term: String? = nil) {
        self.types = types
        self.term = term
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
                .filter(\.$parentType ~~? input.types)
                .sort(\.$createdAt, .descending)
                .with(\.$image)
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
