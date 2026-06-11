import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Book]> {

    static func listBooks(database: Database, permission: BasePermissionResolver<QueryBuilder<Book>>) -> Self {
        PlainCommand { input in
            let query = Book.query(on: database)
                .join(Preview.self, on: \Book.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image) }
                .with(\.$cover)
                .with(\.$owner)
                .with(\.$post)
            if let since = input.since { query.filter(Preview.self, \Preview.$createdAt > since) }
            if let before = input.before { query.filter(Preview.self, \Preview.$createdAt < before) }
            try await permission.grant(query)
            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListCatalogueItemInput, [Book]> {

    static var listBooks: Self {
        CommandFactory { request in
            .listBooks(database: request.commandDB, permission: request.permissions.books.list)
            .logged(name: "List books", logger: request.logger)
        }
    }
}
