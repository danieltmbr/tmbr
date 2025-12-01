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
    
    struct QuoteListQuery: Decodable {
        var types: Set<String>?
    }
    
    struct QuoteSearchQuery: Decodable {
        var term: String
        var types: Set<String>?
    }
    
    struct QuoteResponse: Content {
        let body: String
        let noteID: Int
        let preview: PreviewResponse
    }
    
    @Sendable
    private func list(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteListQuery.self)

        let query = Quote
            .query(on: request.db)
            .with(\.$note) { note in note.with(\.$attachment) }
            .filter(Preview.self, \.$parentType ~~? payload.types)
            .sort(\Quote.$createdAt, .descending)
        
        try await request.permissions.quotes.query(query)
        
        return try await query.all().map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: try quote.note.requireID(),
                preview: PreviewResponse(
                    preview: quote.note.attachment,
                    baseURL: request.baseURL
                )
            )
        }
    }
    
    @Sendable
    private func random(request: Request) async throws -> QuoteResponse {
        let query = Quote
            .query(on: request.db)
            .with(\.$note) { note in note.with(\.$attachment) }
            .sort(.sql(unsafeRaw: "RANDOM()")).limit(1)
        
        try await request.permissions.quotes.query(query)
            
        guard let quote = try await query.first() else {
            throw Abort(.notFound)
        }
        
        return QuoteResponse(
            body: quote.body,
            noteID: try quote.note.requireID(),
            preview: PreviewResponse(
                preview: quote.note.attachment,
                baseURL: request.baseURL
            )
        )
    }
    
    @Sendable
    private func search(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteSearchQuery.self)
        let term = payload.term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !term.isEmpty else { return [] }
        
        let query = Quote
            .query(on: request.db)
            .with(\.$note) { note in note.with(\.$attachment) }
            .filter(Preview.self, \.$parentType ~~? payload.types)
            .group(.or) { group in
                let sql = "text ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                group.filter(.sql(unsafeRaw: sql))
            }

        try await request.permissions.quotes.query(query)

        return try await query.all().map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: try quote.note.requireID(),
                preview: PreviewResponse(
                    preview: quote.note.attachment,
                    baseURL: request.baseURL
                )
            )
        }
    }
}
