import Vapor
import WebAuth
import Fluent
import WebCore
import TmbrCore

struct PlaylistsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let playlistsRoute = routes.grouped("api", "playlists")

        // GET /api/playlists — paginated list of the authenticated user's playlists
        playlistsRoute.get { request async throws -> PageResult<PlaylistResponse> in
            let pageQuery = try request.query.decode(PageQuery.self)
            let input = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
            let playlists = try await request.commands.playlists.list(input)
            let previewIDs = playlists.map { $0.$preview.id }
            async let notesByPreviewID = request.commands.notes.grouped(previewIDs)
            let playlistIDs = playlists.compactMap(\.id)
            let tracksByPlaylistID: [PlaylistID: [Preview]] = try await withThrowingTaskGroup(of: (PlaylistID, [Preview]).self) { group in
                for playlistID in playlistIDs {
                    group.addTask { (playlistID, try await request.commands.previews.listContainerPreviews("playlist", playlistID)) }
                }
                return try await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
            }
            let resolvedNotes = try await notesByPreviewID
            let baseURL = request.baseURL
            return PageResult(from: playlists, limit: input.limit) { playlist in
                PlaylistResponse(
                    playlist: playlist,
                    notes: resolvedNotes[playlist.$preview.id] ?? [],
                    trackPreviews: playlist.id.flatMap { tracksByPlaylistID[$0] } ?? [],
                    baseURL: baseURL
                )
            }
        }

        // GET /api/playlists/:playlistID
        playlistsRoute.get(":playlistID") { request async throws -> PlaylistResponse in
            guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Playlist ID")
            }
            async let playlist = request.commands.playlists.fetch(playlistID, for: .read)
            async let notes = request.commands.notes.query(id: playlistID, of: Playlist.previewType)
            async let trackPreviews = request.commands.previews.listContainerPreviews("playlist", playlistID)
            return try PlaylistResponse(
                playlist: await playlist,
                notes: await notes,
                trackPreviews: await trackPreviews,
                baseURL: request.baseURL
            )
        }

        // POST /api/playlists
        playlistsRoute.post { request async throws -> PlaylistResponse in
            let payload = try request.content.decode(PlaylistPayload.self)
            return try await request.commands.transaction { commands in
                let playlistInput = PlaylistInput(payload: payload)
                let playlist = try await commands.playlists.create(playlistInput)
                try await playlist.$preview.load(on: request.commandDB)
                try await playlist.preview.$image.load(on: request.commandDB)
                try await playlist.preview.$catalogueCategory.load(on: request.commandDB)
                let notesInput = payload.notes.map {
                    BatchCreateNoteInput(
                        attachment: playlist.preview,
                        notes: $0.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return PlaylistResponse(
                    playlist: playlist,
                    notes: notes ?? [],
                    baseURL: request.baseURL
                )
            }
        }

        // PUT /api/playlists/:playlistID
        playlistsRoute.put(":playlistID") { request async throws -> PlaylistResponse in
            guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Playlist ID")
            }
            let payload = try request.content.decode(PlaylistPayload.self)
            let input = PlaylistInput(payload: payload)
            return try await request.commands.transaction { commands in
                let playlist = try await commands.playlists.edit(input.edit(id: playlistID))
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(playlist.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                try await playlist.$preview.load(on: request.commandDB)
                try await playlist.preview.$image.load(on: request.commandDB)
                try await playlist.preview.$catalogueCategory.load(on: request.commandDB)
                let notes = try await commands.notes.query(id: playlistID, of: Playlist.previewType)
                return PlaylistResponse(playlist: playlist, notes: notes, baseURL: request.baseURL)
            }
        }

        // DELETE /api/playlists/:playlistID
        playlistsRoute.delete(":playlistID") { req async throws -> HTTPStatus in
            guard let playlistID = req.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Playlist ID")
            }
            try await req.commands.transaction { commands in
                try await commands.previews.deleteContainerEntries(
                    DeleteContainerEntriesInput(containerType: "playlist", containerID: playlistID)
                )
                try await commands.playlists.delete(playlistID)
            }
            return .noContent
        }

        // POST /api/playlists/:playlistID/notes
        playlistsRoute.post(":playlistID", "notes") { request async throws -> NoteResponse in
            guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Playlist ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let playlist = try await request.commands.playlists.fetch(playlistID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: playlist.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
