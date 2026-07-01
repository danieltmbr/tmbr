import WebCore
import Foundation
import Vapor
import Fluent
import WebAuth
import TmbrCore

struct MovieEditorViewModel: Encodable, Sendable {


    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let director: String

    private let coverId: Int?

    private let coverSourceURL: String?

    private let coverThumbnailURL: String?

    private let genre: String

    private let notes: [NoteEditorViewModel]

    private let releaseDate: String

    private let resourceURLs: [String]

    private let submit: Form.Submit

    private let title: String

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String? = nil,
        access: Access = .private,
        director: String = "",
        coverId: Int? = nil,
        coverSourceURL: String? = nil,
        coverThumbnailURL: String? = nil,
        genre: String = "",
        notes: [NoteEditorViewModel] = [],
        releaseDate: String = "",
        resourceURLs: [String] = [],
        submit: Form.Submit,
        title: String = "",
        csrf: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.access = access
        self.director = director
        self.coverId = coverId
        self.coverSourceURL = coverSourceURL
        self.coverThumbnailURL = coverThumbnailURL
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.submit = submit
        self.title = title
        self._csrf = csrf
        self.error = error
    }

    init(
        movie: Movie,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try movie.requireID()
        let coverId = movie.$cover.id
        let coverThumbnailURL: String?
        if let cover = movie.cover {
            coverThumbnailURL = "\(baseURL)/gallery/data/\(cover.thumbnailKey)"
        } else {
            coverThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(movie.title)'",
            access: movie.access,
            director: movie.director ?? "",
            coverId: coverId,
            coverSourceURL: nil,
            coverThumbnailURL: coverThumbnailURL,
            genre: movie.genre ?? "",
            notes: notes.map { NoteEditorViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access, language: $0.language) },
            releaseDate: movie.releaseDate?.formatted(.releaseDate) ?? "",
            resourceURLs: movie.resourceURLs,
            submit: Form.Submit(
                action: "/movies/\(id)",
                label: "Save"
            ),
            title: movie.title,
            csrf: csrf
        )
    }
}

extension Template where Model == MovieEditorViewModel {
    static let movieEditor = Template(name: "Catalogue/Movies/movie-editor")
}

extension Page {
    static var createMovie: Self {
        Page(template: .movieEditor) { req in
            try await req.permissions.movies.create()
            let submit = Form.Submit(
                action: "/movies/new",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return MovieEditorViewModel(pageTitle: "New movie", submit: submit, csrf: csrf)
        }
        .noStore()
    }

    static var editMovie: Self {
        Page(template: .movieEditor) { request in
            guard let movieID = request.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Movie ID is incorrect or missing.")
            }
            async let movie = request.commands.movies.fetch(movieID, for: .write)
            async let notes = request.commands.notes.query(id: movieID, of: Movie.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await MovieEditorViewModel(
                movie: movie,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
        .noStore()
    }
}

private struct MoviePreviewPayload: Content {
    let title: String
    let director: String?
    let genre: String?
    let releaseDate: String?
    let coverURL: String?
    let resourceURLs: String?
    let notes: String
}

extension Page {
    static var moviePreview: Self {
        Page(template: .movie) { req in
            try await req.permissions.movies.create.grant()
            let payload = try req.content.decode(MoviePreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<MovieMetadata>.movie
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            return MovieViewModel(
                id: 0,
                allowsNewNote: false,
                cover: payload.coverURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                director: payload.director,
                genre: payload.genre,
                notes: notes,
                notesEndpoint: "",
                post: nil,
                releaseDate: payload.releaseDate,
                resources: resources,
                title: "Preview: \(payload.title)"
            )
        }
    }
}
