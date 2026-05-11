import Vapor
import Fluent
import AuthKit
import Core

struct SongsWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(songID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let songsRoute = routes.grouped("songs")
        
        songsRoute.get (page: . songs)

        songsRoute.get(":songID", page: .song)

//        songsRoute.get("new", page: .createSong)
//        songsRoute.post("new", use: createSong)
//
//        songsRoute.get("metadata", use: metadata)
//
//        songsRoute.get(":songID", "edit", page: .editSong)
//        songsRoute.post(":songID", use: updateSong)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> SongMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.songs.metadata(url)
    }

    @Sendable
    private func createSong(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updateSong(_ req: Request) async throws -> Response {
        guard let songID = req.parameters.get("songID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Song ID")
        }
        return try await handleEditorSubmission(req, mode: .update(songID: songID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(SongEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let song = try await req.commands.transaction { commands in
                let songInput = SongInput(payload: payload)
                let song: Song

                switch mode {
                case .create:
                    song = try await commands.songs.create(songInput)
                case .update(let songID):
                    song = try await commands.songs.edit(songInput.edit(id: songID))
                }

                // Create notes if provided (only for create mode)
                if case .create = mode, !payload.notes.isEmpty {
                    let preview = try await commands.previews.fetch(song.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { NoteInput(body: $0, access: payload.access) }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                }

                return song
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/songs/\(song.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func renderEditorWithError(
        _ req: Request,
        mode: EditorMode,
        error: Error
    ) async throws -> Response {
        let submitted = (try? req.content.decode(SongEditorPayload.self)) ?? SongEditorPayload()
        let submit: Form.Submit
        let songID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            songID = nil
            submit = Form.Submit(action: "/songs/new", label: "Save")
            pageTitle = "New song"
        case .update(let id):
            songID = id
            submit = Form.Submit(action: "/songs/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.title)'"
        }

        let csrf = UUID().uuidString
        let model = SongEditorViewModel(
            id: songID,
            pageTitle: pageTitle,
            access: submitted.access,
            album: submitted.album ?? "",
            artist: submitted.artist,
            genre: submitted.genre ?? "",
            notes: submitted.notes,
            releaseDate: submitted.releaseDate?.formatted(.iso8601.year().month().day()) ?? "",
            resourceURLs: submitted.resourceURLs,
            submit: submit,
            title: submitted.title,
            csrf: csrf,
            error: editorErrorHTML(for: error, on: req)
        )

        let view = try await Template.songEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    private func editorErrorHTML(for error: Error, on req: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please <a href=\"/signin?return=\(req.url.path)\">sign in</a> and try again."
            case .forbidden:
                return "You don't have permission to perform this action."
            case .notFound:
                return "This song doesn't exist or isn't available."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        if error is ValidationsError {
            return "Title and artist are required."
        }
        return "Something went wrong. Please try again."
    }
}
