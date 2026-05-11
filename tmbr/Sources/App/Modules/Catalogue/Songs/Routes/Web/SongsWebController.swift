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

        songsRoute.get("new", page: .createSong)
        songsRoute.post("new", use: createSong)

        songsRoute.get("metadata", use: metadata)

        songsRoute.get(":songID", "edit", page: .editSong)
        songsRoute.post(":songID", use: updateSong)

        songsRoute.post("preview", page: .songPreview)
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

            // Resolve artwork: use existing ID, or lookup/upload from URL
            let artworkId = try await resolveArtwork(payload: payload, on: req)

            let song = try await req.commands.transaction { commands in
                let songInput = SongInput(payload: payload, artworkId: artworkId)
                let song: Song

                switch mode {
                case .create:
                    song = try await commands.songs.create(songInput)
                case .update(let songID):
                    song = try await commands.songs.edit(songInput.edit(id: songID))
                }

                // Create notes if provided (only for create mode)
                if case .create = mode {
                    let preview = try await commands.previews.fetch(song.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
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

    private func resolveArtwork(payload: SongEditorPayload, on req: Request) async throws -> ImageID? {
        // If we already have an artwork ID (from drag-drop), use it
        if let artworkId = payload.artworkId {
            return artworkId
        }

        // If we have an artwork URL (from metadata), lookup or upload
        guard let artworkURL = payload.artworkSourceURL else {
            return nil
        }

        // Check if we already have this image in gallery
        if let existingImage = try await req.commands.gallery.lookup(artworkURL) {
            return try existingImage.requireID()
        }

        // Upload the image from URL
        let alt = payload.title.isEmpty ? "Album artwork" : payload.title
        let newImage = try await req.commands.gallery.addFromURL(
            ImageURLPayload(url: artworkURL, alt: alt)
        )
        return try newImage.requireID()
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

        let noteViewModels = submitted.notes.map {
            SongEditorViewModel.NoteViewModel(body: $0.body, access: $0.access)
        }

        let csrf = UUID().uuidString
        let model = SongEditorViewModel(
            id: songID,
            pageTitle: pageTitle,
            access: submitted.access,
            album: submitted.album ?? "",
            artist: submitted.artist,
            artworkId: submitted.artworkId,
            artworkSourceURL: submitted.artworkSourceURL,
            artworkThumbnailURL: submitted.artworkSourceURL,
            genre: submitted.genre ?? "",
            notes: noteViewModels,
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
