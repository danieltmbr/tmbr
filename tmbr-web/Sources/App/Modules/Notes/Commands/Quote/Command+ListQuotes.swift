import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

extension Command where Self == PlainCommand<QuoteQueryPayload, [Quote]> {

    static func listQuotes(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Quote>>
    ) -> Self {
        PlainCommand { input in
            let query = Quote
                .query(on: database)
                .with(\.$note) { note in
                    note.with(\.$attachment) { attachment in
                        attachment.with(\.$image)
                        attachment.with(\.$catalogueCategory)
                    }
                }
                .with(\.$post) { post in
                    post.with(\.$attachment) { attachment in
                        attachment.with(\.$image)
                        attachment.with(\.$catalogueCategory)
                    }
                }
                .sort(\Quote.$createdAt, .descending)
            if let categoryIDs = input.categoryIDs {
                // Inner-joining Note→Preview naturally excludes post-sourced quotes,
                // which have no catalogue category. This is the desired behaviour.
                query
                    .join(Note.self, on: \Quote.$note.$id == \Note.$id)
                    .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                    .filter(Preview.self, \.$catalogueCategory.$id ~~ categoryIDs)
            }
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<QuoteQueryPayload, [Quote]> {

    static var listQuotes: Self {
        CommandFactory { request in
            .listQuotes(
                database: request.commandDB,
                permission: request.permissions.quotes.query
            )
            .logged(
                name: "List quotes",
                logger: request.logger
            )
        }
    }
}
