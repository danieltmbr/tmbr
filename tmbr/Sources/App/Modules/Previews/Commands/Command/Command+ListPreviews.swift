import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct PreviewQueryInput: Sendable {
    let types: Set<String>?
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
