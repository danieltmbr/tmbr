import Vapor
import Fluent
import Foundation
import AuthKit
import PostgresKit

struct QuotesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let quotes = routes.grouped("quotes")
        quotes.get(use: list)
        quotes.get("of-the-day", use: ofTheDay)
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
        
        try await request.permissions.quotes.query(query)
        
        if let types = payload.types {
            query.filter(Preview.self, \.$parentType ~~ types)
        }
        
        query.sort(\Quote.$createdAt, .descending)
        
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
    private func ofTheDay(request: Request) async throws -> QuoteResponse {
        let user = request.auth.get(User.self)
        let query = Quote
            .query(on: request.db)
            .with(\.$note) { note in note.with(\.$attachment) }
        
        try await request.permissions.quotes.query(query)
        
        query.sort(.sql(unsafeRaw: "RANDOM()")).limit(1)
            
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

        try await request.permissions.quotes.query(query)
        
        if let types = payload.types {
            query.filter(Preview.self, \.$parentType ~~ types)
        }

        query.group(.or) { group in
            let sql = "text ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
            group.filter(.sql(unsafeRaw: sql))
        }
        
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
