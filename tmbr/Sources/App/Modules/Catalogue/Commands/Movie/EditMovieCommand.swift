import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditMovieInput {
    
    fileprivate let id: MovieID
    
    fileprivate let movie: MovieInput
    
    init(id: MovieID, movie: MovieInput) {
        self.id = id
        self.movie = movie
    }
    
    fileprivate func validate() throws {
        try movie.validate()
    }
}

struct EditMovieCommand: Command {
    
    private let configure: MovieConfiguration
    
    private let database: Database

    private let permission: AuthPermissionResolver<Movie>
    
    init(
        configure: MovieConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Movie>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }
    
    func execute(_ input: EditMovieInput) async throws -> Movie {
        guard let movie = try await Movie.find(input.id, on: database) else {
            throw Abort(.notFound, reason: "Movie not found")
        }
        try await permission.grant(movie)
        try input.validate()
        configure(movie, with: input.movie)
        
        try await database.transaction { db in
            try await movie.save(on: db)
            if movie.access == .private {
                try await movie.$movieNotes.load(on: db, include: \.$note)
                movie.notes.forEach { $0.access = $0.access && movie.access }
                try await movie.notes.update(on: db)
            }
        }
        return movie
    }
}

extension CommandFactory<EditMovieInput, Movie> {
    
    static var editMovie: Self {
        CommandFactory { request in
            EditMovieCommand(
                database: request.application.db,
                permission: request.permissions.movies.edit
            )
            .logged(logger: request.logger)
        }
    }
}

extension CommandResolver where Input == EditMovieInput {
    
    func callAsFunction(
        _ movieID: MovieID,
        with payload: MoviePayload
    ) async throws -> Output {
        let input = EditMovieInput(
            id: movieID,
            movie: MovieInput(payload: payload)
        )
        return try await self.callAsFunction(input)
    }
}
