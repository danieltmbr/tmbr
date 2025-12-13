import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateMovieInput {
    
    fileprivate let movie: MovieInput
    
    fileprivate let notes: [NoteInput]
    
    init(payload: MoviePayload) {
        movie = MovieInput(payload: payload)
        notes = payload.notes?.map(NoteInput.init) ?? []
    }
    
    fileprivate func validate() throws {
        try movie.validate()
        try notes.forEach { try $0.validate() }
    }
}

struct CreateMovieCommand: Command {
    
    typealias Input = CreateMovieInput
    
    typealias Output = Movie
    
    private let configure: MovieConfiguration

    private let database: Database
        
    private let permission: AuthPermissionResolver<Void>

    init(
        configure: MovieConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Void>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }

    func execute(_ input: CreateMovieInput) async throws -> Movie {
        let user = try await permission.grant()
        try input.validate()
        return try await database.transaction { db in
            let movie = Movie(owner: user.userID)
            configure(movie, with: input.movie)
            try await movie.save(on: database)
            
            let movieID = try movie.requireID()
            let previewID = try movie.preview.requireID()
            let notes = input.notes.map { note in
                Note(
                    attachmentID: previewID,
                    authorID: user.userID,
                    access: note.access && movie.access,
                    body: note.body
                )
            }
            try await notes.create(on: db)
            
            let movieNotes = try notes.map { note in
                MovieNote(movie: movieID, note: try note.requireID())
            }
            try await movieNotes.create(on: db)
            try await movie.$movieNotes.load(on: db, include: \.$note)
            return movie
        }
    }
}

extension CommandFactory<CreateMovieInput, Movie> {

    static var createMovie: Self {
        CommandFactory { request in
            CreateMovieCommand(
                database: request.commandDB,
                permission: request.permissions.movies.create
            )
            .logged(logger: request.logger)
        }
    }
}
