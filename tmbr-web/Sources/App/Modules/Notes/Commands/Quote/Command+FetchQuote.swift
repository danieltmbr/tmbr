import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth
import TmbrCore

extension Command where Self == PlainCommand<QuoteID, Quote> {

    static func fetchQuote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Quote>>
    ) -> Self {
        PlainCommand { quoteID in
            let query = Quote
                .query(on: database)
                .filter(\.$id == quoteID)
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
            try await permission.grant(query)
            guard let quote = try await query.first() else {
                throw Abort(.notFound, reason: "Quote not found")
            }
            return quote
        }
    }
}

extension CommandFactory<QuoteID, Quote> {

    static var fetchQuote: Self {
        CommandFactory { request in
            .fetchQuote(
                database: request.commandDB,
                permission: request.permissions.quotes.query
            )
            .logged(
                name: "Fetch Quote",
                logger: request.logger
            )
        }
    }
}
