import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<QuoteQueryPayload, [Quote]> {
    
    static func listQuotes(
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
                .sort(\Quote.$createdAt, .descending)
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
