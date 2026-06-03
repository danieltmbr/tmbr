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
                .join(Note.self, on: \Quote.$note.$id == \Note.$id)
                .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                .with(\.$note) { note in
                    note.with(\.$attachment) { attachment in
                        attachment.with(\.$image)
                    }
                }
                .sort(.sql(unsafeRaw: "RANDOM()"))
            switch (input.types, input.categories) {
            case (let types?, let cats?):
                query.group(.or) { group in
                    group.filter(Preview.self, \.$parentType ~~ types)
                    group.group(.and) { inner in
                        inner.filter(Preview.self, \.$parentType == nil)
                        inner.filter(Preview.self, \.$category ~~ cats)
                    }
                }
            case (let types?, nil):
                query.filter(Preview.self, \.$parentType ~~ types)
            case (nil, let cats?):
                query.filter(Preview.self, \.$parentType == nil)
                query.filter(Preview.self, \.$category ~~ cats)
            case (nil, nil):
                break
            }
            query.limit(1)
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
                database: request.commandDB,
                permission: request.permissions.quotes.query
            )
            .logged(
                name: "Random Quote",
                logger: request.logger
            )
        }
    }
}
