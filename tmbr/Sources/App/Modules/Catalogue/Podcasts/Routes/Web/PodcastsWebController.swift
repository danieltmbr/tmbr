import Vapor
import Fluent
import AuthKit
import Core

struct PodcastsWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(podcastID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let podcastsRoute = routes.grouped("podcasts")
        let recoveringRoute = routes.grouped("podcasts")
            .grouped(RecoverMiddleware())

        recoveringRoute.get(page: .podcasts)

        recoveringRoute.get(":podcastID", page: .podcast)

        recoveringRoute.get("new", page: .createPodcast)
        recoveringRoute.post("new", use: createPodcast)

        podcastsRoute.get("metadata", use: metadata)
        podcastsRoute.get("lookup", use: lookupDialog)

        recoveringRoute.get(":podcastID", "edit", page: .editPodcast)
        recoveringRoute.post(":podcastID", use: updatePodcast)

        recoveringRoute.post("preview", page: .podcastPreview)

        podcastsRoute.post(":podcastID", "notes", use: createNote)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> PodcastMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.podcasts.metadata(url)
    }

    @Sendable
    private func lookupDialog(_ request: Request) async throws -> Response {
        let url = try request.query.get(String.self, at: "url")
        let excludeID = try? request.query.get(Int.self, at: "excludeID")
        guard let podcast = try await request.commands.podcasts.lookup(url),
              let podcastID = podcast.id,
              podcastID != excludeID
        else {
            return Response(status: .notFound)
        }
        let model = AlertDialog(
            id: "duplicate-alert",
            message: "You already have \"\(podcast.episodeTitle)\" from \(podcast.title).",
            primaryAction: .init(id: "duplicate-dismiss", label: "Continue editing"),
            secondaryAction: .init(id: "duplicate-podcast-link", label: "Go to podcast", href: "/podcasts/\(podcastID)")
        )
        let view = try await Template.alertDialog.render(model, with: request.view)
        return try await view.encodeResponse(for: request)
    }

    @Sendable
    private func createPodcast(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updatePodcast(_ req: Request) async throws -> Response {
        guard let podcastID = req.parameters.get("podcastID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Podcast ID")
        }
        return try await handleEditorSubmission(req, mode: .update(podcastID: podcastID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(PodcastEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let artworkId = try await resolveArtwork(payload: payload, on: req)

            let podcast = try await req.commands.transaction { commands in
                let podcastInput = PodcastInput(payload: payload, artworkId: artworkId)
                let podcast: Podcast

                switch mode {
                case .create:
                    podcast = try await commands.podcasts.create(podcastInput)
                    let preview = try await commands.previews.fetch(podcast.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                case .update(let podcastID):
                    podcast = try await commands.podcasts.edit(podcastInput.edit(id: podcastID))
                    let preview = try await commands.previews.fetch(podcast.$preview.id, for: .write)
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

                return podcast
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/podcasts/\(podcast.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func resolveArtwork(payload: PodcastEditorPayload, on req: Request) async throws -> ImageID? {
        if let artworkId = payload.artworkId {
            return artworkId
        }
        guard let artworkURL = payload.artworkSourceURL else {
            return nil
        }
        if let existingImage = try await req.commands.gallery.lookup(artworkURL) {
            return try existingImage.requireID()
        }
        let alt = payload.episodeTitle.isEmpty ? "Podcast artwork" : payload.episodeTitle
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
        let submitted = (try? req.content.decode(PodcastEditorPayload.self)) ?? PodcastEditorPayload()
        let submit: Form.Submit
        let podcastID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            podcastID = nil
            submit = Form.Submit(action: "/podcasts/new", label: "Save")
            pageTitle = "New podcast"
        case .update(let id):
            podcastID = id
            submit = Form.Submit(action: "/podcasts/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.episodeTitle)'"
        }

        let noteViewModels = submitted.notes.map {
            PodcastEditorViewModel.NoteViewModel(id: $0.id, body: $0.body, access: $0.access)
        }

        let csrf = UUID().uuidString
        let model = PodcastEditorViewModel(
            id: podcastID,
            pageTitle: pageTitle,
            access: submitted.access,
            artworkId: submitted.artworkId,
            artworkSourceURL: submitted.artworkSourceURL,
            artworkThumbnailURL: submitted.artworkSourceURL,
            episodeNumber: submitted.episodeNumber.map(String.init) ?? "",
            episodeTitle: submitted.episodeTitle,
            genre: submitted.genre ?? "",
            notes: noteViewModels,
            releaseDate: submitted.releaseDate?.formatted(.iso8601.year().month().day()) ?? "",
            resourceURLs: submitted.resourceURLs,
            seasonNumber: submitted.seasonNumber.map(String.init) ?? "",
            submit: submit,
            title: submitted.title,
            csrf: csrf,
            error: editorErrorHTML(for: error, on: req)
        )

        let view = try await Template.podcastEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        do {
            let podcast = try await request.commands.podcasts.fetch(podcastID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: podcast.$preview.id
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
                return "This podcast doesn't exist or isn't available."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        if error is ValidationsError {
            return "Episode title and show title are required."
        }
        return "Something went wrong. Please try again."
    }
}
