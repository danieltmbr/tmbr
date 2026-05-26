import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

typealias EditMovieInput = EditInput<Movie, MovieInput>

extension CommandFactory<EditMovieInput, Movie> {
    
    static var editMovie: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .movie,
                database: request.commandDB,
                permission: request.permissions.movies.edit,
                queryNotes: request.commands.notes.query,
                validate: .movie
            )
            .logged(name: "Edit Movie Command", logger: request.logger)
        }
    }
}
