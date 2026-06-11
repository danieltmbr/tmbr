import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct CatalogueAPIController: RouteCollection {
    
    private let mapper: CatalogueQueryMapper
    
    init(mapper: CatalogueQueryMapper = .init()) {
        self.mapper = mapper
    }
    
    func boot(routes: RoutesBuilder) throws {
        let catalogue = routes.grouped("api", "catalogue")
        catalogue.get(use: list)
        catalogue.get("search", use: search)
        catalogue.get("item", ":previewID", use: getItem)
        catalogue.post("item", ":previewID", "notes", use: createItemNote)
        catalogue.post("new", use: createItem)
        catalogue.get("new", "metadata", use: metadata)

        // GET /api/catalogue/orphans — paginated orphan items for native app sync
        catalogue.get("orphans", use: listOrphans)

        let quotes = catalogue.grouped("quotes")
        quotes.get(use: quoteList)
        quotes.get("search", use: quoteSearch)
        quotes.get("random", use: randomQuote)
    }

    // MARK: - Catalogue item handlers

    @Sendable
    private func getItem(request: Request) async throws -> PreviewResponse {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid preview ID")
        }
        let preview = try await request.commands.previews.fetch(previewID, for: .read)
        return PreviewResponse(preview: preview, baseURL: request.baseURL)
    }

    @Sendable
    private func createItemNote(request: Request) async throws -> NoteResponse {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid preview ID")
        }
        let payload = try request.content.decode(NotePayload.self)
        _ = try await request.commands.previews.fetch(previewID, for: .write)
        let input = CreateNoteInput(body: payload.body, access: payload.access, attachmentID: previewID)
        let note = try await request.commands.notes.create(input)
        try await note.$attachment.load(on: request.commandDB)
        try await note.$author.load(on: request.commandDB)
        return NoteResponse(note: note, baseURL: request.baseURL)
    }

    @Sendable
    private func createItem(request: Request) async throws -> PreviewResponse {
        let payload = try request.content.decode(CatalogueNewPayload.self)
        let user = try await request.permissions.previews.create.grant()
        let userID = user.userID
        let input = CreatePreviewItemInput(
            title: payload.title.trimmingCharacters(in: .whitespaces),
            subtitle: {
                let s = payload.subtitle?.trimmingCharacters(in: .whitespaces) ?? ""
                return s.isEmpty ? nil : s
            }(),
            access: payload.access,
            artworkID: payload.artworkID,
            externalLink: {
                let u = payload.url?.trimmingCharacters(in: .whitespaces) ?? ""
                return u.isEmpty ? nil : u
            }(),
            categoryName: payload.category,
            ownerID: userID
        )
        let preview = try await request.commands.previews.create(input)
        return PreviewResponse(preview: preview, baseURL: request.baseURL)
    }

    @Sendable
    private func metadata(request: Request) async throws -> CatalogueItemMetadataResponse {
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

    // MARK: - Catalogue list handlers

    @Sendable
    private func listOrphans(request: Request) async throws -> PageResult<PreviewResponse> {
        let pageQuery = try request.query.decode(PageQuery.self)
        let limit = pageQuery.limit ?? 50
        let input = PreviewQueryInput(kind: .orphan, since: pageQuery.since, before: pageQuery.cursorDate, limit: limit + 1)
        let previews = try await request.commands.previews.list(input)
        let baseURL = request.baseURL
        return makePage(from: previews, limit: limit, cursorDate: { $0.createdAt }) {
            $0.map { PreviewResponse(preview: $0, baseURL: baseURL) }
        }
    }

    @Sendable
    private func list(request: Request) async throws -> [PreviewResponse] {
        let payload = try request.content.decode(CatalogueQueryPayload.self)
        let input = mapper.toPreviewQuery(from: payload)
        let previews = try await request.commands.previews.list(input)
        let baseURL = request.baseURL
        return previews.map { PreviewResponse(preview: $0, baseURL: baseURL) }
    }
    
    @Sendable
    private func search(request: Request) async throws -> [PreviewResponse] {
        let payload = try request.content.decode(CatalogueQueryPayload.self)
        let input = mapper.toNotesQuery(from: payload)
        let notes = try await request.commands.notes.search(input)
        let baseURL = request.baseURL
        return notes.map {
            PreviewResponse(
                primaryInfo: $0.attachment.primaryInfo,
                secondaryInfo: $0.body,
                image: $0.attachment.image.map { image in
                    ImageResponse(image: image, baseURL: baseURL)
                },
                resources: $0.attachment.externalLinks,
                source: PreviewResponse.Source(
                    id: $0.attachment.parentID,
                    type: $0.attachment.catalogueCategory?.slug ?? "item"
                )
            )
        }
    }
    
    @Sendable
    private func quoteList(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.content.decode(CatalogueQueryPayload.self)
        let input = mapper.toQuoteQuery(from: payload)
        let quotes = try await request.commands.quotes.list(input)
        let baseURL = request.baseURL
        return quotes.map {
            QuoteResponse(quote: $0, baseURL: baseURL)
        }
    }
    
    @Sendable
    private func quoteSearch(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.content.decode(CatalogueQueryPayload.self)
        let input = mapper.toQuoteQuery(from: payload)
        let quotes = try await request.commands.quotes.search(input)
        let baseURL = request.baseURL
        return quotes.map {
            QuoteResponse(quote: $0, baseURL: baseURL)
        }
    }
    
    @Sendable
    private func randomQuote(request: Request) async throws -> QuoteResponse {
        let payload = try request.content.decode(CatalogueQueryPayload.self)
        let input = mapper.toQuoteQuery(from: payload)
        let quote = try await request.commands.quotes.random(input)
        return QuoteResponse(quote: quote, baseURL: request.baseURL)
    }
}

