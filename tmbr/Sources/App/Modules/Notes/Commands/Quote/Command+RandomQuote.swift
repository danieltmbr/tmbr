import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<QuoteQueryPayload, Quote> {
    static func randomQuote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Quote>>
    ) -> Self {
        PlainCommand { input in
            let query = Quote
                .query(on: database)
                .with(\.$note) { note in
                    note.with(\.$attachment) { attachment in
                        attachment.with(\.$image)
                    }
                }
                .filter(Preview.self, \.$parentType ~~? input.types)
                .sort(.sql(unsafeRaw: "RANDOM()"))
                .limit(1)
            try await permission.grant(query)
            guard let quote = try await query.first() else {
                throw Abort(.notFound, reason: "No quote found")
            }
            return quote
        }
    }
}

extension CommandFactory<QuoteQueryPayload, Quote> {
    
    static var randomQuote: Self {
        CommandFactory { request in
            .randomQuote(
                database: request.db,
                permission: request.permissions.quotes.query
            )
            .logged(
                name: "Random Quote",
                logger: request.logger
            )
        }
    }
}
