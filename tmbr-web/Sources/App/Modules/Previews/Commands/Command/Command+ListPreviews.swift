import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct PreviewQueryInput: Sendable {

    let term: String?

    let types: Set<String>?

    let categories: Set<String>?

    init(
        term: String? = nil,
        types: Set<String>? = nil,
        categories: Set<String>? = nil
    ) {
        self.term = term
        self.types = types
        self.categories = categories
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

            switch (input.types, input.categories) {
            case (let types?, let cats?):
                query.group(.or) { group in
                    group.filter(\.$parentType ~~ types)
                    group.group(.and) { inner in
                        inner.filter(\.$parentType == nil)
                        inner.filter(\.$category ~~ cats)
                    }
                }
            case (let types?, nil):
                query.filter(\.$parentType ~~ types)
            case (nil, let cats?):
                query.filter(\.$parentType == nil)
                query.filter(\.$category ~~ cats)
            case (nil, nil):
                break
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
