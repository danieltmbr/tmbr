import Vapor
import Foundation
import AuthKit
import Core

struct MovieViewModel: Encodable, Sendable {
    
    private let id: MovieID
    
    private let cover: ImageViewModel?
    
    private let director: String?
    
    private let genre: String?
    
    private let notes: [NoteViewModel]
    
    private let post: PostItemViewModel?
    
    private let releaseYear: String
    
    private let resources: [Hyperlink]
    
    private let title: String
    
    init(
        id: MovieID,
        cover: ImageViewModel?,
        director: String?,
        genre: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        releaseYear: String,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.cover = cover
        self.director = director
        self.genre = genre
        self.notes = notes
        self.post = post
        self.releaseYear = releaseYear
        self.resources = resources
        self.title = title
    }
    
    init(
        movie: Movie,
        notes: [Note],
        baseURL: String,
        platform: Platform<Void> = .movie
    ) throws {
        self.init(
            id: try movie.requireID(),
            cover: movie.cover.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            director: movie.director,
            genre: movie.genre,
            notes: try notes.map(NoteViewModel.init),
            post: try movie.post.map(PostItemViewModel.init),
            releaseYear: movie.releaseDate.formatted(.year),
            resources: movie.resourceURLs.compactMap(platform.hyperlink),
            title: movie.title
        )
    }
}

extension Template where Model == MovieViewModel {
    static let movie = Template(name: "Catalogue/Movies/movie")
}

extension Page {
    static var movie: Self {
        Page(template: .movie) { request in
            guard let movieID = request.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            return try await request.commands.transaction { commands in
                async let movie = commands.movies.fetch(movieID, for: .read)
                async let notes = commands.notes.query(id: movieID, of: Movie.previewType)
                
                return try MovieViewModel(
                    movie: await movie,
                    notes: await notes,
                    baseURL: request.baseURL
                )
            }
        }
    }
}
