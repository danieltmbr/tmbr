import Vapor
import Fluent
import AuthKit
import Core

struct MoviesWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(movieID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let moviesRoute = routes.grouped("movies")
        let recoveringRoute = routes.grouped("movies")
            .grouped(RecoverMiddleware())

        recoveringRoute.get(page: .movies)

        recoveringRoute.get(":movieID", page: .movie)

        recoveringRoute.get("new", page: .createMovie)
        recoveringRoute.post("new", use: createMovie)

        moviesRoute.get("metadata", use: metadata)
        moviesRoute.get("lookup", use: lookupDialog)

        recoveringRoute.get(":movieID", "edit", page: .editMovie)
        recoveringRoute.post(":movieID", use: updateMovie)

        recoveringRoute.post("preview", page: .moviePreview)

        moviesRoute.post(":movieID", "notes", use: createNote)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> MovieMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.movies.metadata(url)
    }

    @Sendable
    private func lookupDialog(_ request: Request) async throws -> Response {
        let url = try request.query.get(String.self, at: "url")
        let excludeID = try? request.query.get(Int.self, at: "excludeID")
        guard let movie = try await request.commands.movies.lookup(url),
              let movieID = movie.id,
              movieID != excludeID
        else {
            return Response(status: .notFound)
        }
        let directorSuffix = movie.director.map { ", directed by \($0)" } ?? ""
        let model = AlertDialog(
            id: "duplicate-alert",
            message: "You already have \(movie.title)\(directorSuffix).",
            primaryAction: .init(id: "duplicate-dismiss", label: "Continue editing"),
            secondaryAction: .init(id: "duplicate-movie-link", label: "Go to movie", href: "/movies/\(movieID)")
        )
        let view = try await Template.alertDialog.render(model, with: request.view)
        return try await view.encodeResponse(for: request)
    }

    @Sendable
    private func createMovie(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updateMovie(_ req: Request) async throws -> Response {
        guard let movieID = req.parameters.get("movieID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Movie ID")
        }
        return try await handleEditorSubmission(req, mode: .update(movieID: movieID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(MovieEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let coverId = try await resolveCover(payload: payload, on: req)

            let movie = try await req.commands.transaction { commands in
                let movieInput = MovieInput(payload: payload, coverId: coverId)
                let movie: Movie

                switch mode {
                case .create:
                    movie = try await commands.movies.create(movieInput)
                    let preview = try await commands.previews.fetch(movie.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                case .update(let movieID):
                    movie = try await commands.movies.edit(movieInput.edit(id: movieID))
                    let preview = try await commands.previews.fetch(movie.$preview.id, for: .write)
                    let syncEntries = payload.notes.map { entry in
                        SyncNoteEntry(
                            id: entry.noteID,
                            body: entry.body,
                            access: entry.access,
                            deleted: entry.deleted ?? false
                        )
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }

                return movie
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/movies/\(movie.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func resolveCover(payload: MovieEditorPayload, on req: Request) async throws -> ImageID? {
        if let coverId = payload.coverId {
            return coverId
        }
        guard let coverURL = payload.coverSourceURL else {
            return nil
        }
        if let existingImage = try await req.commands.gallery.lookup(coverURL) {
            return try existingImage.requireID()
        }
        let alt = payload.title.isEmpty ? "Movie cover" : payload.title
        let newImage = try await req.commands.gallery.addFromURL(
            ImageURLPayload(url: coverURL, alt: alt)
        )
        return try newImage.requireID()
    }

    private func renderEditorWithError(
        _ req: Request,
        mode: EditorMode,
        error: Error
    ) async throws -> Response {
        let submitted = (try? req.content.decode(MovieEditorPayload.self)) ?? MovieEditorPayload()
        let submit: Form.Submit
        let movieID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            movieID = nil
            submit = Form.Submit(action: "/movies/new", label: "Save")
            pageTitle = "New movie"
        case .update(let id):
            movieID = id
            submit = Form.Submit(action: "/movies/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.title)'"
        }

        let noteViewModels = submitted.notes.map {
            MovieEditorViewModel.NoteViewModel(id: $0.id, body: $0.body, access: $0.access)
        }

        let csrf = UUID().uuidString
        let model = MovieEditorViewModel(
            id: movieID,
            pageTitle: pageTitle,
            access: submitted.access,
            director: submitted.director ?? "",
            coverId: submitted.coverId,
            coverSourceURL: submitted.coverSourceURL,
            coverThumbnailURL: submitted.coverSourceURL,
            genre: submitted.genre ?? "",
            notes: noteViewModels,
            releaseDate: submitted.releaseDate?.formatted(.iso8601.year().month().day()) ?? "",
            resourceURLs: submitted.resourceURLs,
            submit: submit,
            title: submitted.title,
            csrf: csrf,
            error: editorErrorHTML(for: error, on: req)
        )

        let view = try await Template.movieEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let movieID = request.parameters.get("movieID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        do {
            let movie = try await request.commands.movies.fetch(movieID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: movie.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            let model = try NoteViewModel(note: note, isEditable: true)
            let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
            return try await view.encodeResponse(for: request)
        } catch {
            return Response(status: .unprocessableEntity)
        }
    }

    private func editorErrorHTML(for error: Error, on req: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please <a href=\"/signin?return=\(req.url.path)\">sign in</a> and try again."
            case .forbidden:
                return "You don't have permission to perform this action."
            case .notFound:
                return "This movie doesn't exist or isn't available."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        if error is ValidationsError {
            return "Title is required."
        }
        return "Something went wrong. Please try again."
    }
}
