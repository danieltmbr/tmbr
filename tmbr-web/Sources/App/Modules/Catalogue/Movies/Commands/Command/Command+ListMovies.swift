import Foundation
import Core
import Fluent

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Movie]> {

    static func listMovies(database: Database) -> Self {
        PlainCommand { input in
            var query = Movie.query(on: database)
                .filter(\.$owner.$id == input.ownerID)
                .join(Preview.self, on: \Movie.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Movie]> {

    static var listMovies: Self {
        CommandFactory { request in
            .listMovies(database: request.commandDB)
            .logged(name: "List movies", logger: request.logger)
        }
    }
}
