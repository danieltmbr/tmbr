import Vapor
import Core
import AuthKit
import TmbrCore

struct PreviewsWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let recovering = routes.grouped(RecoverMiddleware())

        recovering.get("catalogue", "item", ":previewID", page: .catalogueItem)
        recovering.post("catalogue", "item", ":previewID", "notes", use: createNote)

        recovering.get("catalogue", "new", page: .catalogueNew)
        recovering.get("catalogue", "new", "metadata", use: metadata)
        recovering.post("catalogue", "new", use: createItem)
        recovering.post("catalogue", "new", "preview", page: .cataloguePreview)
    }

    // MARK: - Notes

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        do {
            _ = try await request.commands.previews.fetch(previewID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: previewID
            )
            let note = try await request.commands.notes.create(input)
            let model = try NoteViewModel(note: note, isEditable: true)
            let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
            return try await view.encodeResponse(for: request)
        } catch {
            return Response(status: .unprocessableEntity)
        }
    }

    // MARK: - Catalogue New

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

            let user = try request.auth.require(User.self)
            let userID = try user.requireID()

            let rawCategory = payload.category.trimmingCharacters(in: .whitespaces).lowercased()
            let category = rawCategory.isEmpty ? "link" : rawCategory
            guard category != "track" else {
                return try await renderNewWithError(request, payload: payload, error: "That category name is reserved.")
            }

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
                        category: category,
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
        let user = try? request.auth.require(User.self)
        let categories: [String]
        if let userID = user.flatMap({ try? $0.requireID() }) {
            categories = (try? await request.commands.previews.listShallowCategories(userID)) ?? []
        } else {
            categories = []
        }
        let noteViewModels = (payload?.notes ?? []).map {
            CatalogueNewViewModel.NoteViewModel(id: $0.id, body: $0.body, access: $0.access)
        }
        let artworkURL: String?
        if let raw = payload?.artworkSourceURL, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            artworkURL = raw
        } else {
            artworkURL = nil
        }
        let vm = CatalogueNewViewModel(
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
        let view = try await Template.catalogueNew.render(vm, with: request.view)
        return try await view.encodeResponse(for: request)
    }
}

// MARK: - Types

struct CatalogueItemMetadataResponse: Content, Sendable {
    let title: String?
    let subtitle: String?
    let artworkURL: String?
}

struct CatalogueNewPayload: Decodable, Sendable {
    let url: String?
    let title: String
    let subtitle: String?
    let category: String
    let access: Access
    private let artworkIDRaw: String?
    private let artworkSourceURLRaw: String?
    let notes: [NotePayload]

    var artworkID: ImageID? {
        guard let raw = artworkIDRaw, !raw.isEmpty else { return nil }
        return Int(raw)
    }

    var artworkSourceURL: String? {
        guard let raw = artworkSourceURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case subtitle
        case category
        case access
        case artworkIDRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case notes
    }
}
