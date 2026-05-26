import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateMovieCommand: Command {
    
    private let configure: ModelConfiguration<Movie, MovieInput>
    
    private let database: Database
    
    private let permission: AuthPermissionResolver<Void>
    
    private let validate: Validator<MovieInput>
    
    init(
        configure: ModelConfiguration<Movie, MovieInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<MovieInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }
    
    func execute(_ input: MovieInput) async throws -> Movie {
        let user = try await permission.grant()
        try validate(input)
        
        var movie = Movie(owner: user.userID)
        configure(&movie, with: input)
        try await movie.save(on: database)
        
        return movie
    }
}

extension CommandFactory<MovieInput, Movie> {
    
    static var createMovie: Self {
        CommandFactory { request in
            CreateMovieCommand(
                configure: .movie,
                database: request.commandDB,
                permission: request.permissions.movies.create,
                validate: .movie
            )
            .logged(logger: request.logger)
        }
    }
}
