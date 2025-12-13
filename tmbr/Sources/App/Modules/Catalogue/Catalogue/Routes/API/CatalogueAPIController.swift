import Vapor
import Core
import Fluent
import AuthKit

struct CatalogueAPIController: RouteCollection {
    
    private let mapper: CatalogueQueryMapper
    
    init(mapper: CatalogueQueryMapper = .init()) {
        self.mapper = mapper
    }
    
    func boot(routes: RoutesBuilder) throws {
        let catalogue = routes.grouped("catalogue")
        catalogue.get(use: list)
        catalogue.get("search", use: search)
        // TODO: return domain object based on preview
        // catalogue.get(":previewID", use: get)
        
        let quotes = catalogue.grouped("quotes")
        quotes.get(use: quoteList)
        quotes.get("search", use: quoteSearch)
        quotes.get("random", use: randomQuote)
    }

    // MARK: - Handlers

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
                    type: $0.attachment.parentType
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

