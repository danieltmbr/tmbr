import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

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
                    }
                }
                .filter(Preview.self, \.$parentType ~~? input.types)
                .group(.or) { group in
                    let sql = "body ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                    group.filter(.sql(unsafeRaw: sql))
                }
                .sort(\Quote.$createdAt, .descending)
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
