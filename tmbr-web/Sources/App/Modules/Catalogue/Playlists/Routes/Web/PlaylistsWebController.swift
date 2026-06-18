import Vapor
import Fluent
import CoreAuth
import CoreWeb
import CoreTmbr

struct PlaylistsWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(playlistID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let playlistsRoute = routes.grouped("playlists")
        let recoveringRoute = routes.grouped("playlists")
            .grouped(RecoverMiddleware())

        recoveringRoute.get(page: .playlists)

        recoveringRoute.get(":playlistID", page: .playlist)

        recoveringRoute.get("new", page: .createPlaylist)
        recoveringRoute.post("new", use: createPlaylist)

        playlistsRoute.get("metadata", use: metadata)
        recoveringRoute.post("preview", page: .playlistPreview)

        recoveringRoute.get(":playlistID", "edit", page: .editPlaylist)
        recoveringRoute.post(":playlistID", use: updatePlaylist)

        recoveringRoute.post(":playlistID", "notes", use: createNote)
        recoveringRoute.post(":playlistID", "sync-tracks", use: syncTracks)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> PlaylistMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.playlists.metadata(url)
    }

    @Sendable
    private func createPlaylist(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updatePlaylist(_ req: Request) async throws -> Response {
        guard let playlistID = req.parameters.get("playlistID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Playlist ID")
        }
        return try await handleEditorSubmission(req, mode: .update(playlistID: playlistID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(PlaylistEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let artworkId = try await resolveArtwork(payload: payload, on: req)

            let playlist = try await req.commands.transaction { commands in
                let playlistInput = PlaylistInput(payload: payload, artworkId: artworkId)
                let playlist: Playlist

                switch mode {
                case .create:
                    playlist = try await commands.playlists.create(playlistInput)
                    let preview = try await commands.previews.fetch(playlist.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                    if let tracks = playlistInput.tracks, !tracks.isEmpty {
                        try await commands.previews.importTracks(
                            ImportAlbumTracksInput(
                                albumID: try playlist.requireID(),
                                access: payload.access,
                                artist: nil,
                                ownerID: preview.ownerID,
                                tracks: tracks,
                                containerType: "playlist"
                            )
                        )
                    }
                case .update(let playlistID):
                    playlist = try await commands.playlists.edit(playlistInput.edit(id: playlistID))
                    let preview = try await commands.previews.fetch(playlist.$preview.id, for: .write)
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

                return playlist
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/playlists/\(playlist.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func resolveArtwork(payload: PlaylistEditorPayload, on req: Request) async throws -> ImageID? {
        if let artworkId = payload.artworkId {
            return artworkId
        }

        guard let artworkURL = payload.artworkSourceURL else {
            return nil
        }

        if let existingImage = try await req.commands.gallery.lookup(artworkURL) {
            return try existingImage.requireID()
        }

        let alt = payload.title.isEmpty ? "Playlist artwork" : payload.title
        do {
            let newImage = try await req.commands.gallery.addFromURL(
                ImageURLPayload(url: artworkURL, alt: alt)
            )
            return try newImage.requireID()
        } catch {
            guard let fallbackURL = payload.artworkFallbackURL else { throw error }
            if let existingImage = try await req.commands.gallery.lookup(fallbackURL) {
                return try existingImage.requireID()
            }
            let fallbackImage = try await req.commands.gallery.addFromURL(
                ImageURLPayload(url: fallbackURL, alt: alt)
            )
            return try fallbackImage.requireID()
        }
    }

    private func renderEditorWithError(
        _ req: Request,
        mode: EditorMode,
        error: Error
    ) async throws -> Response {
        let submitted = (try? req.content.decode(PlaylistEditorPayload.self)) ?? PlaylistEditorPayload()
        let submit: Form.Submit
        let playlistID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            playlistID = nil
            submit = Form.Submit(action: "/playlists/new", label: "Save")
            pageTitle = "New playlist"
        case .update(let id):
            playlistID = id
            submit = Form.Submit(action: "/playlists/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.title)'"
        }

        let noteViewModels = submitted.notes.map {
            NoteEditorViewModel(id: $0.id, body: $0.body, access: $0.access, language: $0.language ?? .en)
        }

        let csrf = UUID().uuidString
        let model = PlaylistEditorViewModel(
            id: playlistID,
            pageTitle: pageTitle,
            access: submitted.access,
            artworkId: submitted.artworkId,
            artworkSourceURL: submitted.artworkSourceURL,
            artworkThumbnailURL: submitted.artworkSourceURL,
            description: submitted.description ?? "",
            notes: noteViewModels,
            resourceURLs: submitted.resourceURLs,
            submit: submit,
            title: submitted.title,
            csrf: csrf,
            error: editorErrorHTML(for: error, on: req)
        )

        let view = try await Template.playlistEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    private struct SyncTracksPayload: Decodable {
        let _csrf: String?
    }

    @Sendable
    private func syncTracks(_ request: Request) async throws -> Response {
        guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        let payload = try? request.content.decode(SyncTracksPayload.self)
        guard let submittedCSRF = payload?._csrf,
              submittedCSRF == request.session.data["csrf.sync"] else {
            throw Abort(.forbidden, reason: "Invalid form token. Please reload the page and try again.")
        }
        request.session.data["csrf.sync"] = nil
        let playlist = try await request.commands.playlists.fetch(playlistID, for: .write)
        let platform = Platform<PlaylistMetadata>.playlist
        let platformURL = playlist.resourceURLs.compactMap { URL(string: $0) }.first { platform.name(for: $0) != nil }
        guard let platformURL else {
            throw Abort(.badRequest, reason: "No streaming URL found for this playlist")
        }
        let metadata = try await request.commands.playlists.metadata(platformURL)
        guard let tracks = metadata.tracks, !tracks.isEmpty else {
            return request.redirect(to: "/playlists/\(playlistID)")
        }
        try await request.commands.transaction { commands in
            let preview = try await commands.previews.fetch(playlist.$preview.id, for: .write)
            try await commands.previews.deleteContainerEntries(
                DeleteContainerEntriesInput(containerType: "playlist", containerID: playlistID)
            )
            try await commands.previews.importTracks(
                ImportAlbumTracksInput(
                    albumID: playlistID,
                    access: playlist.access,
                    artist: nil,
                    ownerID: preview.ownerID,
                    tracks: tracks,
                    containerType: "playlist"
                )
            )
        }
        return request.redirect(to: "/playlists/\(playlistID)")
    }

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        do {
            let playlist = try await request.commands.playlists.fetch(playlistID, for: .write)
            return try await request.createNoteResponse(attachmentID: playlist.$preview.id)
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
                return "This playlist doesn't exist or isn't available."
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
