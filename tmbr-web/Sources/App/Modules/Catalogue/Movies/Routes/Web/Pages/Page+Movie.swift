import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct MovieViewModel: Encodable, Sendable {

    private let id: MovieID

    private let cover: ImageViewModel?

    private let allowsNewNote: Bool

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: MovieID,
        cover: ImageViewModel?,
        allowsNewNote: Bool,
        info: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.cover = cover
        self.allowsNewNote = allowsNewNote
        self.info = info
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.post = post
        self.resources = resources
        self.title = title
    }

    init(
        id: MovieID,
        allowsNewNote: Bool,
        cover: ImageViewModel?,
        director: String?,
        genre: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        title: String
    ) {
        self.init(
            id: id,
            cover: cover,
            allowsNewNote: allowsNewNote,
            info: {
                let parts = [director, genre, releaseDate].compactMap { $0 }.filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: ", ")
            }(),
            notes: notes,
            notesEndpoint: notesEndpoint,
            post: post,
            resources: resources,
            title: title
        )
    }

    init(
        movie: Movie,
        notes: [Note],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<MovieMetadata> = .movie
    ) throws {
        let movieID = try movie.requireID()
        self.init(
            id: movieID,
            allowsNewNote: allowsNewNote,
            cover: movie.cover.flatMap { ImageViewModel(image: $0, baseURL: baseURL) },
            director: movie.director,
            genre: movie.genre,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/movies/\(movieID)/notes",
            post: try movie.post.map(PostItemViewModel.init),
            releaseDate: movie.releaseDate?.formatted(.releaseDate),
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
            async let movieTask = request.commands.movies.fetch(movieID, for: .read)
            async let notesTask = request.commands.notes.query(id: movieID, of: Movie.previewType)
            let resolvedMovie = try await movieTask
            let allowsNewNote = (try? await request.permissions.movies.edit.grant(resolvedMovie)) != nil
            return try MovieViewModel(
                movie: resolvedMovie,
                notes: await notesTask,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
