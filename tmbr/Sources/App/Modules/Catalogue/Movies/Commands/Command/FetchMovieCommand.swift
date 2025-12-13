import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

final class FetchMovieCommand: FetchCommand<Movie>, @unchecked Sendable {
    
    override func execute(_ params: FetchParameters<FetchCommand<Movie>.ItemID>) async throws -> Movie {
        let movie = try await super.execute(params)
        async let cover: Void = movie.$cover.load(on: database)
        async let notes = movie.$movieNotes.load(on: database, include: \.$note)
        async let owner: Void = movie.$owner.load(on: database)
        async let post: Void = movie.$post.load(on: database)
        _ = try await (cover, owner, notes, post)
        return movie
    }
}

extension CommandFactory<FetchParameters<MovieID>, Movie> {
    
    static var fetchMovie: Self {
        CommandFactory { request in
            FetchMovieCommand(
                database: request.commandDB,
                readPermission: request.permissions.movies.access,
                writePermission: request.permissions.movies.edit
            )
            .logged(logger: request.logger)
        }
    }
}
