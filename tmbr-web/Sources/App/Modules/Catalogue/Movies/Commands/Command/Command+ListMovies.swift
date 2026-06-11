import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Movie]> {

    static func listMovies(database: Database, permission: AuthPermissionResolver<Void>) -> Self {
        PlainCommand { input in
            let user = try await permission.grant()
            var query = Movie.query(on: database)
                .filter(\.$owner.$id == user.userID)
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
            .listMovies(database: request.commandDB, permission: request.permissions.movies.list)
            .logged(name: "List movies", logger: request.logger)
        }
    }
}
