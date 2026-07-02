import Vapor
import WebAuth
import Fluent
import WebCore
import TmbrCore

private struct PodcastLookupResponse: Content, Sendable {
    let id: Int
    let episodeTitle: String
    let title: String
    let detailURL: String
}

struct PodcastsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let podcastsRoute = routes.grouped("api", "podcasts")

        // GET /api/podcasts — paginated list of the authenticated user's podcasts
        podcastsRoute.get { request async throws -> PageResult<PodcastResponse> in
            let pageQuery = try request.query.decode(PageQuery.self)
            let input = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
            let podcasts = try await request.commands.podcasts.list(input)
            let previewIDs = podcasts.map { $0.$preview.id }
            let notesByPreviewID = try await request.commands.notes.grouped(previewIDs)
            let baseURL = request.baseURL
            return try PageResult(from: podcasts, limit: input.limit) { podcast in
                try PodcastResponse(podcast: podcast, baseURL: baseURL, notes: notesByPreviewID[podcast.$preview.id] ?? [])
            }
        }

        // GET /api/podcasts/lookup?url=
        podcastsRoute.get("lookup") { request async throws -> PodcastLookupResponse in
            let url = try request.query.get(String.self, at: "url")
            guard let podcast = try await request.commands.podcasts.lookup(url),
                  let podcastID = podcast.id
            else {
                throw Abort(.notFound)
            }
            return PodcastLookupResponse(
                id: podcastID,
                episodeTitle: podcast.episodeTitle,
                title: podcast.title,
                detailURL: "/podcasts/\(podcastID)"
            )
        }

        // GET /api/podcasts/:podcastID
        podcastsRoute.get(":podcastID") { request async throws -> PodcastResponse in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Podcast ID")
            }
            async let podcast = request.commands.podcasts.fetch(podcastID, for: .read)
            async let notes = request.commands.notes.query(id: podcastID, of: Podcast.previewType)
            return try PodcastResponse(
                podcast: try await podcast,
                baseURL: request.baseURL,
                notes: try await notes
            )
        }

        // POST /api/podcasts
        podcastsRoute.post(use: { request async throws -> PodcastResponse in
            let payload = try request.content.decode(PodcastPayload.self)
            return try await request.commands.transaction { commands in
                let podcastInput = PodcastInput(payload: payload)
                let podcast = try await commands.podcasts.create(podcastInput)
                try await podcast.$preview.load(on: request.commandDB)
                try await podcast.preview.$image.load(on: request.commandDB)
                try await podcast.preview.$catalogueCategory.load(on: request.commandDB)
                let notesInput = payload.notes.map { entries in
                    BatchCreateNoteInput(
                        attachment: podcast.preview,
                        notes: entries.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return try PodcastResponse(
                    podcast: podcast,
                    baseURL: request.baseURL,
                    notes: notes ?? []
                )
            }
        })

        // PUT /api/podcasts/:podcastID
        podcastsRoute.put(":podcastID") { request async throws -> PodcastResponse in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Podcast ID")
            }
            let payload = try request.content.decode(PodcastPayload.self)
            let input = PodcastInput(payload: payload)
            return try await request.commands.transaction { commands in
                let podcast = try await commands.podcasts.edit(input.edit(id: podcastID))
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(podcast.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                try await podcast.$preview.load(on: request.commandDB)
                try await podcast.preview.$image.load(on: request.commandDB)
                try await podcast.preview.$catalogueCategory.load(on: request.commandDB)
                let notes = try await commands.notes.query(id: podcastID, of: Podcast.previewType)
                return try PodcastResponse(podcast: podcast, baseURL: request.baseURL, notes: notes)
            }
        }

        // DELETE /api/podcasts/:podcastID
        podcastsRoute.delete(":podcastID") { req async throws -> HTTPStatus in
            guard let podcastID = req.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Podcast ID")
            }
            try await req.commands.podcasts.delete(podcastID)
            return .noContent
        }

        // POST /api/podcasts/:podcastID/notes
        podcastsRoute.post(":podcastID", "notes") { request async throws -> NoteResponse in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Podcast ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let podcast = try await request.commands.podcasts.fetch(podcastID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: podcast.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
