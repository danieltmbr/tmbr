import Vapor
import Fluent
import Foundation
import AuthKit
import PostgresKit
import Core

struct QuotesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let quotes = routes.grouped("quotes")
        quotes.get(use: list)
        quotes.get("random", use: random)
        quotes.get("search", use: search)
    }
    
    @Sendable
    private func list(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quotes = try await request.commands.quotes.list(payload)
        return quotes.map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: quote.$note.id,
                preview: PreviewResponse(
                    preview: quote.note.attachment,
                    baseURL: request.baseURL
                )
            )
        }
    }
    
    @Sendable
    private func random(request: Request) async throws -> QuoteResponse {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quote = try await request.commands.quotes.random(payload)
        return QuoteResponse(
            body: quote.body,
            noteID: quote.$note.id,
            preview: PreviewResponse(
                preview: quote.note.attachment,
                baseURL: request.baseURL
            )
        )
    }
    
    @Sendable
    private func search(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quotes = try await request.commands.quotes.search(payload)
        return quotes.map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: quote.$note.id,
                preview: PreviewResponse(
                    preview: quote.note.attachment,
                    baseURL: request.baseURL
                )
            )
        }
    }
}
