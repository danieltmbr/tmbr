import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

extension Command where Self == PlainCommand<QuoteQueryPayload, [Quote]> {

    static func searchQuote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Quote>>
    ) -> Self {
        PlainCommand { input in
            guard let term = input.term?.trimmed, !term.isEmpty else {
                return []
            }
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
                .group(.or) { group in
                    let sql = "body ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                    group.filter(.sql(unsafeRaw: sql))
                }
                .sort(\Quote.$createdAt, .descending)
            if let categoryIDs = input.categoryIDs {
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

    static var searchQuote: Self {
        CommandFactory { request in
            .searchQuote(
                database: request.commandDB,
                permission: request.permissions.quotes.query
            )
            .logged(
                name: "Search Quote",
                logger: request.logger
            )
        }
    }
}
