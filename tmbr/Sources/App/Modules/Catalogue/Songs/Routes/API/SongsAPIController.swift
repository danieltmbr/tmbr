import Vapor
import AuthKit
import Fluent
import Core

struct SongsAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {

        let songsRoute = routes.grouped("api", "songs")
        
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
            async let song = request.commands.songs.edit(songID, with: input)
            async let notes = request.commands.notes.query(id: songID, of: Song.previewType)
            return SongResponse(
                song: try await song,
                notes: try await notes,
                baseURL: request.baseURL
            )
        }
        
        // DELETE /api/songs/:songID
        songsRoute.delete(":songID") { req async throws -> HTTPStatus in
            guard let songID = req.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Song ID")
            }
            try await req.commands.songs.delete(songID)
            return .noContent
        }
    }
}
