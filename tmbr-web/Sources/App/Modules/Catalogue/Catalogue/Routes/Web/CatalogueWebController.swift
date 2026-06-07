import Vapor
import Core
import AuthKit
import TmbrCore

struct CatalogueWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let recovering = routes.grouped(RecoverMiddleware())

        recovering.get("catalogue", page: .catalogue)

        recovering.get("catalogue", "item", ":previewID", page: .catalogueItem)
        recovering.get("catalogue", "item", ":previewID", "edit", page: .catalogueItemEditor)
        recovering.post("catalogue", "item", ":previewID", use: updateItem)
        recovering.post("catalogue", "item", ":previewID", "notes", use: createNote)

        recovering.get("catalogue", "new", page: .catalogueNew)
        recovering.get("catalogue", "new", "metadata", use: metadata)
        recovering.post("catalogue", "new", use: createItem)
        recovering.post("catalogue", "new", "preview", page: .cataloguePreview)
    }

    // MARK: - Catalogue item notes

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            return Response(status: .badRequest)
        }
        do {
            _ = try await request.commands.previews.fetch(previewID, for: .write)
            return try await request.createNoteResponse(attachmentID: previewID)
        } catch {
            return Response(status: .unprocessableEntity)
        }
    }

    // MARK: - Catalogue item edit

    @Sendable
    private func updateItem(_ request: Request) async throws -> Response {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            return Response(status: .badRequest)
        }
        do {
            let payload = try request.content.decode(CatalogueNewPayload.self)

            guard !payload.title.trimmingCharacters(in: .whitespaces).isEmpty else {
                return try await renderEditorWithError(request, previewID: previewID, payload: payload, error: "Title is required.")
            }

            let preview = try await request.commands.previews.fetch(previewID, for: .write)
            try await request.permissions.previews.edit.grant(preview)

            let artworkID = try await resolveArtwork(payload: payload, title: payload.title, on: request)

            let updatedPreview = try await request.commands.previews.update(
                UpdatePreviewItemInput(
                    previewID: previewID,
                    title: payload.title.trimmingCharacters(in: .whitespaces),
                    subtitle: {
                        let s = payload.subtitle?.trimmingCharacters(in: .whitespaces) ?? ""
                        return s.isEmpty ? nil : s
                    }(),
                    artworkID: artworkID,
                    externalLink: {
                        let u = payload.url?.trimmingCharacters(in: .whitespaces) ?? ""
                        return u.isEmpty ? nil : u
                    }(),
                    categoryName: payload.category
                )
            )
            let syncEntries = payload.notes.map { SyncNoteEntry(id: $0.noteID, body: $0.body, access: $0.access, deleted: $0.deleted ?? false) }
            _ = try await request.commands.notes.sync(SyncNotesInput(attachment: updatedPreview, parentAccess: preview.parentAccess, entries: syncEntries))
            return request.redirect(to: "/catalogue/item/\(previewID)")
        } catch {
            let payload = try? request.content.decode(CatalogueNewPayload.self)
            return try await renderEditorWithError(request, previewID: previewID, payload: payload, error: errorMessage(for: error, on: request))
        }
    }

    private func renderEditorWithError(_ request: Request, previewID: UUID, payload: CatalogueNewPayload?, error: String) async throws -> Response {
        let categories = ((try? await request.commands.catalogueCategories.list()) ?? []).map(\.name)
        let artworkURL: String?
        if let raw = payload?.artworkSourceURL, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            artworkURL = raw
        } else {
            artworkURL = nil
        }
        let vm = CatalogueEditorViewModel(
            previewID: previewID,
            url: payload?.url,
            title: payload?.title ?? "",
            subtitle: payload?.subtitle,
            artworkURL: artworkURL,
            category: payload?.category ?? "",
            categories: categories,
            error: error
        )
        let view = try await Template.catalogueEditor.render(vm, with: request.view)
        return try await view.encodeResponse(for: request)
    }

    // MARK: - Catalogue new

    @Sendable
    private func metadata(_ request: Request) async throws -> CatalogueItemMetadataResponse {
        let urlString = try request.query.get(String.self, at: "url")
        guard let url = URL(string: urlString) else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }
        let meta = try await request.commands.catalogue.metadata(url)
        return CatalogueItemMetadataResponse(
            title: meta.tags["og:title"],
            subtitle: meta.tags["og:description"] ?? meta.tags["og:site_name"],
            artworkURL: meta.tags["og:image"]
        )
    }

    @Sendable
    private func createItem(_ request: Request) async throws -> Response {
        do {
            let payload = try request.content.decode(CatalogueNewPayload.self)

            guard !payload.title.trimmingCharacters(in: .whitespaces).isEmpty else {
                return try await renderNewWithError(request, payload: payload, error: "Title is required.")
            }

            let user = try await request.permissions.previews.create.grant()
            let userID = user.userID

            let artworkID = try await resolveArtwork(payload: payload, title: payload.title, on: request)

            let preview = try await request.commands.transaction { commands in
                let preview = try await commands.previews.create(
                    CreatePreviewItemInput(
                        title: payload.title.trimmingCharacters(in: .whitespaces),
                        subtitle: {
                            let s = payload.subtitle?.trimmingCharacters(in: .whitespaces) ?? ""
                            return s.isEmpty ? nil : s
                        }(),
                        access: payload.access,
                        artworkID: artworkID,
                        externalLink: {
                            let u = payload.url?.trimmingCharacters(in: .whitespaces) ?? ""
                            return u.isEmpty ? nil : u
                        }(),
                        categoryName: payload.category,
                        ownerID: userID
                    )
                )
                let noteInputs = payload.notes.map { NoteInput(body: $0.body, access: $0.access && payload.access) }
                _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                return preview
            }
            return request.redirect(to: "/catalogue/item/\(preview.id!)")
        } catch {
            let payload = (try? request.content.decode(CatalogueNewPayload.self))
            return try await renderNewWithError(request, payload: payload, error: errorMessage(for: error, on: request))
        }
    }

    private func errorMessage(for error: Error, on request: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please <a href=\"/signin?return=\(request.url.path)\">sign in</a> and try again."
            case .forbidden:
                return "You don't have permission to perform this action."
            default:
                break
            }
        }
        return "Something went wrong. Please try again."
    }

    private func resolveArtwork(payload: CatalogueNewPayload, title: String, on request: Request) async throws -> ImageID? {
        if let artworkID = payload.artworkID {
            return artworkID
        }
        guard let urlString = payload.artworkSourceURL,
              !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        if let existing = try await request.commands.gallery.lookup(urlString) {
            return try existing.requireID()
        }
        let image = try await request.commands.gallery.addFromURL(
            ImageURLPayload(url: urlString, alt: title)
        )
        return try image.requireID()
    }

    private func renderNewWithError(_ request: Request, payload: CatalogueNewPayload?, error: String) async throws -> Response {
        let categories = ((try? await request.commands.catalogueCategories.list()) ?? []).map(\.name)
        let noteViewModels = (payload?.notes ?? []).map {
            NoteEditorViewModel(id: $0.id, body: $0.body, access: $0.access, language: $0.language ?? .en)
        }
        let artworkURL: String?
        if let raw = payload?.artworkSourceURL, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            artworkURL = raw
        } else {
            artworkURL = nil
        }
        let vm = CatalogueEditorViewModel(
            url: payload?.url,
            title: payload?.title ?? "",
            subtitle: payload?.subtitle,
            artworkURL: artworkURL,
            category: payload?.category ?? "",
            access: payload?.access ?? .public,
            categories: categories,
            notes: noteViewModels,
            error: error
        )
        let view = try await Template.catalogueEditor.render(vm, with: request.view)
        return try await view.encodeResponse(for: request)
    }
}
