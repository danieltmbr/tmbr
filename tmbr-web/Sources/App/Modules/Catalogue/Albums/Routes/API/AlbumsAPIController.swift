import Vapor
import AuthKit
import Fluent
import Core
import TmbrCore

private struct AlbumLookupResponse: Content, Sendable {
    let id: Int
    let title: String
    let artist: String
    let detailURL: String
}

struct AlbumsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let albumsRoute = routes.grouped("api", "albums")

        // GET /api/albums/lookup?url=...
        albumsRoute.get("lookup") { request async throws -> AlbumLookupResponse in
            let url = try request.query.get(String.self, at: "url")
            guard let album = try await request.commands.albums.lookup(url),
                  let albumID = album.id
            else {
                throw Abort(.notFound)
            }
            return AlbumLookupResponse(id: albumID, title: album.title, artist: album.artist, detailURL: "/albums/\(albumID)")
        }

        // GET /api/albums/:albumID
        albumsRoute.get(":albumID") { request async throws -> AlbumResponse in
            guard let albumID = request.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Album ID")
            }
            async let album = request.commands.albums.fetch(albumID, for: .read)
            async let notes = request.commands.notes.query(id: albumID, of: Album.previewType)
            return try AlbumResponse(
                album: await album,
                notes: await notes,
                baseURL: request.baseURL
            )
        }

        // POST /api/albums
        albumsRoute.post { request async throws -> AlbumResponse in
            let payload = try request.content.decode(AlbumPayload.self)
            return try await request.commands.transaction { commands in
                let albumInput = AlbumInput(payload: payload)
                let album = try await commands.albums.create(albumInput)
                let notesInput = payload.notes.map {
                    BatchCreateNoteInput(
                        attachment: album.preview,
                        notes: $0.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return AlbumResponse(
                    album: album,
                    notes: notes ?? [],
                    baseURL: request.baseURL
                )
            }
        }

        // PUT /api/albums/:albumID
        albumsRoute.put(":albumID") { request async throws -> AlbumResponse in
            guard let albumID = request.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Album ID")
            }
            let payload = try request.content.decode(AlbumPayload.self)
            let input = AlbumInput(payload: payload)
            return try await request.commands.transaction { commands in
                let album = try await commands.albums.edit(albumID, with: input)
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(album.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                let notes = try await commands.notes.query(id: albumID, of: Album.previewType)
                return AlbumResponse(album: album, notes: notes, baseURL: request.baseURL)
            }
        }

        // DELETE /api/albums/:albumID
        albumsRoute.delete(":albumID") { req async throws -> HTTPStatus in
            guard let albumID = req.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Album ID")
            }
            try await req.commands.previews.deleteContainerEntries(
                DeleteContainerEntriesInput(containerType: "album", containerID: albumID)
            )
            try await req.commands.albums.delete(albumID)
            return .noContent
        }

        // POST /api/albums/:albumID/notes
        albumsRoute.post(":albumID", "notes") { request async throws -> NoteResponse in
            guard let albumID = request.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Album ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let album = try await request.commands.albums.fetch(albumID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: album.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
