import Vapor
import Fluent
import AuthKit
import Core
import TmbrCore

struct AlbumsWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(albumID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let albumsRoute = routes.grouped("albums")
        let recoveringRoute = routes.grouped("albums")
            .grouped(RecoverMiddleware())

        recoveringRoute.get(page: .albums)

        recoveringRoute.get(":albumID", page: .album)

        recoveringRoute.get("new", page: .createAlbum)
        recoveringRoute.post("new", use: createAlbum)

        albumsRoute.get("metadata", use: metadata)
        albumsRoute.get("lookup", use: lookupDialog)
        recoveringRoute.post("preview", page: .albumPreview)

        recoveringRoute.get(":albumID", "edit", page: .editAlbum)
        recoveringRoute.post(":albumID", use: updateAlbum)

        recoveringRoute.post(":albumID", "notes", use: createNote)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> AlbumMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.albums.metadata(url)
    }

    @Sendable
    private func lookupDialog(_ request: Request) async throws -> Response {
        let url = try request.query.get(String.self, at: "url")
        let excludeID = try? request.query.get(Int.self, at: "excludeID")
        guard let album = try await request.commands.albums.lookup(url),
              let albumID = album.id,
              albumID != excludeID
        else {
            return Response(status: .notFound)
        }
        let model = AlertDialog(
            id: "duplicate-alert",
            message: "You already have \(album.title) by \(album.artist).",
            primaryAction: .init(id: "duplicate-dismiss", label: "Continue editing"),
            secondaryAction: .init(id: "duplicate-album-link", label: "Go to album", href: "/albums/\(albumID)")
        )
        let view = try await Template.alertDialog.render(model, with: request.view)
        return try await view.encodeResponse(for: request)
    }

    @Sendable
    private func createAlbum(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updateAlbum(_ req: Request) async throws -> Response {
        guard let albumID = req.parameters.get("albumID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Album ID")
        }
        return try await handleEditorSubmission(req, mode: .update(albumID: albumID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(AlbumEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let artworkId = try await resolveArtwork(payload: payload, on: req)

            let album = try await req.commands.transaction { commands in
                let albumInput = AlbumInput(payload: payload, artworkId: artworkId)
                let album: Album

                switch mode {
                case .create:
                    album = try await commands.albums.create(albumInput)
                    let preview = try await commands.previews.fetch(album.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                    if let tracks = albumInput.tracks, !tracks.isEmpty {
                        try await commands.previews.importTracks(
                            ImportAlbumTracksInput(
                                albumID: try album.requireID(),
                                access: payload.access,
                                artist: payload.artist,
                                ownerID: preview.ownerID,
                                tracks: tracks
                            )
                        )
                    }
                case .update(let albumID):
                    album = try await commands.albums.edit(albumInput.edit(id: albumID))
                    let preview = try await commands.previews.fetch(album.$preview.id, for: .write)
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

                return album
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/albums/\(album.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func resolveArtwork(payload: AlbumEditorPayload, on req: Request) async throws -> ImageID? {
        if let artworkId = payload.artworkId {
            return artworkId
        }

        guard let artworkURL = payload.artworkSourceURL else {
            return nil
        }

        if let existingImage = try await req.commands.gallery.lookup(artworkURL) {
            return try existingImage.requireID()
        }

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
        let submitted = (try? req.content.decode(AlbumEditorPayload.self)) ?? AlbumEditorPayload()
        let submit: Form.Submit
        let albumID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            albumID = nil
            submit = Form.Submit(action: "/albums/new", label: "Save")
            pageTitle = "New album"
        case .update(let id):
            albumID = id
            submit = Form.Submit(action: "/albums/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.title)'"
        }

        let noteViewModels = submitted.notes.map {
            AlbumEditorViewModel.NoteViewModel(id: $0.id, body: $0.body, access: $0.access)
        }

        let csrf = UUID().uuidString
        let model = AlbumEditorViewModel(
            id: albumID,
            pageTitle: pageTitle,
            access: submitted.access,
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

        let view = try await Template.albumEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let albumID = request.parameters.get("albumID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        do {
            let album = try await request.commands.albums.fetch(albumID, for: .write)
            return try await request.createNoteResponse(attachmentID: album.$preview.id)
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
                return "This album doesn't exist or isn't available."
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
