import Foundation
import Core
import Fluent

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Book]> {

    static func listBooks(database: Database) -> Self {
        PlainCommand { input in
            var query = Book.query(on: database)
                .filter(\.$owner.$id == input.ownerID)
                .join(Preview.self, on: \Book.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image) }
                .with(\.$cover)
                .with(\.$owner)
                .with(\.$post)

            if let since = input.since {
                query = query.filter(Preview.self, \Preview.$createdAt > since)
            }
            if let before = input.before {
                query = query.filter(Preview.self, \Preview.$createdAt < before)
            }

            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListCatalogueItemInput, [Book]> {

    static var listBooks: Self {
        CommandFactory { request in
            .listBooks(database: request.commandDB)
            .logged(name: "List books", logger: request.logger)
        }
    }
}
