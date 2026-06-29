import Vapor
import CoreWeb
import CoreTmbr

extension CommandFactory<FetchParameters<MovieID>, Movie> {
    
    static var fetchMovie: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.movies.access,
                writePermission: request.permissions.movies.edit,
                load: \.$cover, \.$owner, \.$post, \.$preview,
                then: { movie, db in
                    try await movie.preview.$image.load(on: db)
                    try await movie.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Movie", logger: request.logger)
        }
    }
}
