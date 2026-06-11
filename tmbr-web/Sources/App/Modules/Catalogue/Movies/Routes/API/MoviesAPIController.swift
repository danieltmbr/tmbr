import Vapor
import AuthKit
import Fluent
import Core
import TmbrCore

private struct MovieLookupResponse: Content, Sendable {
    let id: Int
    let title: String
    let director: String?
    let detailURL: String
}

struct MoviesAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let moviesRoute = routes.grouped("api", "movies")

        // GET /api/movies — paginated list of the authenticated user's movies
        moviesRoute.grouped(AppleSignInAuthenticator()).get { request async throws -> PageResult<MovieResponse> in
            let pageQuery = try request.query.decode(PageQuery.self)
            let limit = pageQuery.limit ?? 50
            let input = ListCatalogueItemInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: limit + 1)
            let movies = try await request.commands.movies.list(input)
            let previewIDs = movies.map { $0.$preview.id }
            let notesByPreviewID = try await request.commands.notes.batchFetch(BatchFetchNotesInput(previewIDs: previewIDs))
            let baseURL = request.baseURL
            return makePage(from: movies, limit: limit, cursorDate: { $0.preview.createdAt }) {
                $0.map { movie in MovieResponse(movie: movie, baseURL: baseURL, notes: notesByPreviewID[movie.$preview.id] ?? []) }
            }
        }

        // GET /api/movies/lookup?url=
        moviesRoute.get("lookup") { request async throws -> MovieLookupResponse in
            let url = try request.query.get(String.self, at: "url")
            guard let movie = try await request.commands.movies.lookup(url),
                  let movieID = movie.id
            else {
                throw Abort(.notFound)
            }
            return MovieLookupResponse(id: movieID, title: movie.title, director: movie.director, detailURL: "/movies/\(movieID)")
        }

        // GET /api/movies/:movieID
        moviesRoute.get(":movieID") { request async throws -> MovieResponse in
            guard let movieID = request.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Movie ID")
            }
            async let movie = request.commands.movies.fetch(movieID, for: .read)
            async let notes = request.commands.notes.query(id: movieID, of: Movie.previewType)
            return MovieResponse(
                movie: try await movie,
                baseURL: request.baseURL,
                notes: try await notes
            )
        }

        // POST /api/movies
        moviesRoute.post(use: { request async throws -> MovieResponse in
            let payload = try request.content.decode(MoviePayload.self)
            return try await request.commands.transaction { commands in
                let movieInput = MovieInput(payload: payload)
                let movie = try await commands.movies.create(movieInput)
                let notesInput = payload.notes.map { entries in
                    BatchCreateNoteInput(
                        attachment: movie.preview,
                        notes: entries.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return MovieResponse(
                    movie: movie,
                    baseURL: request.baseURL,
                    notes: notes ?? []
                )
            }
        })

        // PUT /api/movies/:movieID
        moviesRoute.put(":movieID") { request async throws -> MovieResponse in
            guard let movieID = request.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Movie ID")
            }
            let payload = try request.content.decode(MoviePayload.self)
            let input = MovieInput(payload: payload)
            return try await request.commands.transaction { commands in
                let movie = try await commands.movies.edit(input.edit(id: movieID))
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(movie.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                let notes = try await commands.notes.query(id: movieID, of: Movie.previewType)
                return MovieResponse(movie: movie, baseURL: request.baseURL, notes: notes)
            }
        }

        // DELETE /api/movies/:movieID
        moviesRoute.delete(":movieID") { req async throws -> HTTPStatus in
            guard let movieID = req.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Movie ID")
            }
            try await req.commands.movies.delete(movieID)
            return .noContent
        }

        // POST /api/movies/:movieID/notes
        moviesRoute.post(":movieID", "notes") { request async throws -> NoteResponse in
            guard let movieID = request.parameters.get("movieID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Movie ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let movie = try await request.commands.movies.fetch(movieID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: movie.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
