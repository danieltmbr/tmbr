import Vapor
import AuthKit
import Fluent
import Core
import TmbrCore

private struct SongLookupResponse: Content, Sendable {
    let id: Int
    let title: String
    let artist: String
    let detailURL: String
}

struct SongsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let songsRoute = routes.grouped("api", "songs")

        // GET /api/songs — paginated list of the authenticated user's songs
        songsRoute.get { request async throws -> PageResult<SongResponse> in
            let pageQuery = try request.query.decode(PageQuery.self)
            let input = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
            let songs = try await request.commands.songs.list(input)
            let previewIDs = songs.map { $0.$preview.id }
            let notesByPreviewID = try await request.commands.notes.batchFetch(previewIDs)
            let baseURL = request.baseURL
            return PageResult(from: songs, limit: input.limit) { song in
                SongResponse(song: song, notes: notesByPreviewID[song.$preview.id] ?? [], baseURL: baseURL)
            }
        }

        // GET /api/songs/lookup?url=...
        songsRoute.get("lookup") { request async throws -> SongLookupResponse in
            let url = try request.query.get(String.self, at: "url")
            guard let song = try await request.commands.songs.lookup(url),
                  let songID = song.id
            else {
                throw Abort(.notFound)
            }
            return SongLookupResponse(id: songID, title: song.title, artist: song.artist, detailURL: "/songs/\(songID)")
        }

        // GET /api/songs/:songID
        songsRoute.get(":songID") { request async throws -> SongResponse in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Song ID")
            }
            async let song = request.commands.songs.fetch(songID, for: .read)
            async let notes = request.commands.notes.query(id: songID, of: Song.previewType)
            return try SongResponse(
                song: await song,
                notes: await notes,
                baseURL: request.baseURL
            )
        }
        
        // POST /api/songs
        songsRoute.post(use: { request async throws -> SongResponse in
            let payload = try request.content.decode(SongPayload.self)
            return try await request.commands.transaction { commands in
                let songInput = SongInput(payload: payload)
                let song = try await commands.songs.create(songInput)
                let notesInput = payload.notes.map {
                    BatchCreateNoteInput(
                        attachment: song.preview,
                        notes: $0.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return SongResponse(
                    song: song,
                    notes: notes ?? [],
                    baseURL: request.baseURL
                )
            }
        })
        
        // PUT /api/songs/:songID
        songsRoute.put(":songID") { request async throws -> SongResponse in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Song ID")
            }
            let payload = try request.content.decode(SongPayload.self)
            let input = SongInput(payload: payload)
            return try await request.commands.transaction { commands in
                let song = try await commands.songs.edit(songID, with: input)
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(song.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                let notes = try await commands.notes.query(id: songID, of: Song.previewType)
                return SongResponse(song: song, notes: notes, baseURL: request.baseURL)
            }
        }
        
        // DELETE /api/songs/:songID
        songsRoute.delete(":songID") { req async throws -> HTTPStatus in
            guard let songID = req.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Song ID")
            }
            try await req.commands.songs.delete(songID)
            return .noContent
        }

        // POST /api/songs/promote
        songsRoute.post("promote") { request async throws -> SongResponse in
            struct PromotePayload: Content {
                let previewID: UUID
            }
            let payload = try request.content.decode(PromotePayload.self)
            let song = try await request.commands.songs.promote(payload.previewID)
            let notes = try await request.commands.notes.query(id: song.id!, of: Song.previewType)
            return SongResponse(song: song, notes: notes, baseURL: request.baseURL)
        }

        // POST /api/songs/:songID/notes
        songsRoute.post(":songID", "notes") { request async throws -> NoteResponse in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Song ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let song = try await request.commands.songs.fetch(songID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: song.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
