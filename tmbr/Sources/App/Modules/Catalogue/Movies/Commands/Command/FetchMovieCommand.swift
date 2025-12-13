import Vapor
import Core

extension CommandFactory<FetchParameters<MovieID>, Movie> {
    
    static var fetchMovie: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.movies.access,
                writePermission: request.permissions.movies.edit,
                load: \.$cover, \.$owner, \.$post
            )
            .logged(name: "Fetch Movie", logger: request.logger)
        }
    }
}
