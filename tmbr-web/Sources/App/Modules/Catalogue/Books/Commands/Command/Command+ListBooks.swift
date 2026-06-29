import Foundation
import WebCore
import Fluent
import WebAuth

extension Command where Self == PlainCommand<PageInput, [Book]> {

    static func listBooks(database: Database, permission: BasePermissionResolver<QueryBuilder<Book>>) -> Self {
        PlainCommand { input in
            let query = Book.query(on: database)
                .join(Preview.self, on: \Book.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image).with(\.$catalogueCategory) }
                .with(\.$cover)
                .with(\.$owner)
                .with(\.$post)
            query.page(input)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PageInput, [Book]> {

    static var listBooks: Self {
        CommandFactory { request in
            .listBooks(database: request.commandDB, permission: request.permissions.books.query)
            .logged(name: "List books", logger: request.logger)
        }
    }
}
