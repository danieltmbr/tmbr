import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<String, Movie?> {

    static func lookupMovie(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Movie>>
    ) -> Self {
        PlainCommand { url in
            let escaped = url.replacingOccurrences(of: "'", with: "''")
            let query = Movie.query(on: database)
                .filter(.sql(unsafeRaw: "'\(escaped)' = ANY(movies.resource_urls)"))
            try await permission.grant(query)
            return try await query.first()
        }
    }
}

extension CommandFactory<String, Movie?> {

    static var lookupMovie: Self {
        CommandFactory { request in
            .lookupMovie(
                database: request.commandDB,
                permission: request.permissions.movies.lookup
            )
            .logged(name: "Lookup Movie", logger: request.logger)
        }
    }
}
