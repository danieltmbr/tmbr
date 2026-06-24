import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<PageInput, [Movie]> {

    static func listMovies(database: Database, permission: BasePermissionResolver<QueryBuilder<Movie>>) -> Self {
        PlainCommand { input in
            let query = Movie.query(on: database)
                .join(Preview.self, on: \Movie.$preview.$id == \Preview.$id)
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

extension CommandFactory<PageInput, [Movie]> {

    static var listMovies: Self {
        CommandFactory { request in
            .listMovies(database: request.commandDB, permission: request.permissions.movies.query)
            .logged(name: "List movies", logger: request.logger)
        }
    }
}
