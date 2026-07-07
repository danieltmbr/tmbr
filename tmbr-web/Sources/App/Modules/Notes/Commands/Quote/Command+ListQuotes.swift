import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

struct ListQuotesInput: Sendable {
    let term: String?
    let categoryIDs: Set<Int>?
    let page: PageInput?
}

extension Command where Self == PlainCommand<ListQuotesInput, [Quote]> {

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

            if let term = input.term?.trimmed, !term.isEmpty {
                let safe = term.replacingOccurrences(of: "'", with: "''")
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "quotes.body ILIKE '%\(safe)%'"))
                }
            }

            if let categoryIDs = input.categoryIDs {
                // Inner-joining Note→Preview naturally excludes post-sourced quotes,
                // which have no catalogue category. This is the desired behaviour.
                query
                    .join(Note.self, on: \Quote.$note.$id == \Note.$id)
                    .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                    .filter(Preview.self, \.$catalogueCategory.$id ~~ categoryIDs)
            }

            if let page = input.page {
                let formatter = ISO8601DateFormatter()
                if let since = page.since {
                    let str = formatter.string(from: since)
                    query.filter(.sql(unsafeRaw: "quotes.created_at > '\(str)'::timestamptz"))
                }
                if let before = page.before {
                    let str = formatter.string(from: before)
                    query.filter(.sql(unsafeRaw: "quotes.created_at < '\(str)'::timestamptz"))
                }
                query.limit(page.limit + 1)
            }

            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<ListQuotesInput, [Quote]> {

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
