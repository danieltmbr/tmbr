import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<String, Book?> {

    static func lookupBook(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Book>>
    ) -> Self {
        PlainCommand { url in
            let escaped = url.replacingOccurrences(of: "'", with: "''")
            let query = Book.query(on: database)
                .filter(.sql(unsafeRaw: "'\(escaped)' = ANY(books.resource_urls)"))
            try await permission.grant(query)
            return try await query.first()
        }
    }
}

extension CommandFactory<String, Book?> {

    static var lookupBook: Self {
        CommandFactory { request in
            .lookupBook(
                database: request.commandDB,
                permission: request.permissions.books.lookup
            )
            .logged(name: "Lookup Book", logger: request.logger)
        }
    }
}
