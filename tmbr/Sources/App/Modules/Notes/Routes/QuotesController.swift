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
    private func list(req: Request) async throws -> [QuoteResponse] {
        let payload = try req.query.decode(QuoteListQuery.self)
        var query = Quote.query(on: req.db)
            .with(\.$note) { note in
                note.with(\.$attachment)
            }
            .sort(\Quote.$createdAt, .descending)
        
        if let types = payload.types {
            query = query.filter(Preview.self, \.$ownerType ~~ types)
        }
        
        return try await query.all().map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: try quote.note.requireID(),
                preview: PreviewResponse(preview: quote.note.attachment)
            )
        }
    }
    
    @Sendable
    private func ofTheDay(request: Request) async throws -> QuoteResponse {
        let quote = try await Quote
            .query(on: request.db)
            .with(\.$note) { note in
                note.with(\.$attachment)
            }
            .sort(.sql(unsafeRaw: "RANDOM()"))
            .limit(1)
            .first()
        
        guard let quote else {
            throw Abort(.notFound)
        }
        
        return QuoteResponse(
            body: quote.body,
            noteID: try quote.note.requireID(),
            preview: PreviewResponse(preview: quote.note.attachment)
        )
    }
    
    @Sendable
    private func search(req: Request) async throws -> [QuoteResponse] {
        let payload = try req.query.decode(QuoteSearchQuery.self)
        let term = payload.term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !term.isEmpty else { return [] }
        
        var query = Quote.query(on: req.db)
            .join(Note.self, on: \Quote.$note.$id == \Note.$id)

        if let types = payload.types {
            query = query.filter(Preview.self, \.$ownerType ~~ types)
        }

        query = query.group(.or) { group in
            let sql = "text ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
            group.filter(.sql(unsafeRaw: sql))
        }
        
        return try await query.all().map { quote in
            QuoteResponse(
                body: quote.body,
                noteID: try quote.note.requireID(),
                preview: PreviewResponse(preview: quote.note.attachment)
            )
        }
    }
}
