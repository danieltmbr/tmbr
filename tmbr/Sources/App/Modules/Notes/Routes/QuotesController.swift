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
    
    struct QuoteListQuery: Content {
        var type: String?
    }
    
    struct QuoteSearchQuery: Content {
        var term: String
        var type: String?
    }
    
    struct QuoteResponse: Content {
        let id: Int
        let text: String
        let noteID: Int
        let attachmentType: String
        let attachmentID: Int
    }
    
    @Sendable
    private func list(req: Request) async throws -> [QuoteResponse] {
        let query = try req.query.decode(QuoteListQuery.self)
        
        var quoteQuery = Quote.query(on: req.db)
            .join(Note.self, on: \Quote.$note.$id == \Note.$id)
            .sort(\Quote.$createdAt, .descending)
        
        if let type = query.type {
            quoteQuery = quoteQuery.filter(Note.self, \.$attachmentType == type)
        }
        
        return try await quoteQuery.all().map { quote in
            let note = try quote.joined(Note.self)
            return QuoteResponse(
                id: try quote.requireID(),
                text: quote.body,
                noteID: try note.requireID(),
                attachmentType: note.attachmentType,
                attachmentID: note.attachmentID
            )
        }
    }
    
    @Sendable
    private func ofTheDay(request: Request) async throws -> QuoteResponse {
        let quote = try await Quote
            .query(on: request.db)
            .with(\.$note)
            .sort(.sql(unsafeRaw: "RANDOM()"))
            .limit(1)
            .first()
        
        guard let quote else {
            throw Abort(.notFound)
        }
        
        return QuoteResponse(
            id: try quote.requireID(),
            text: quote.body,
            noteID: try quote.note.requireID(),
            attachmentType: quote.note.attachmentType,
            attachmentID: quote.note.attachmentID
        )
    }
    
    @Sendable
    private func search(req: Request) async throws -> [QuoteResponse] {
        let query = try req.query.decode(QuoteSearchQuery.self)
        let term = query.term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !term.isEmpty else { return [] }
        
        var quoteQuery = Quote.query(on: req.db)
            .join(Note.self, on: \Quote.$note.$id == \Note.$id)

        if let type = query.type {
            quoteQuery = quoteQuery.filter(Note.self, \.$attachmentType == type)
        }

        quoteQuery = quoteQuery.group(.or) { group in
            let sql = "text ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
            group.filter(.sql(unsafeRaw: sql))
        }
        
        return try await quoteQuery.all().map { quote in
            let note = try quote.joined(Note.self)
            return QuoteResponse(
                id: try quote.requireID(),
                text: quote.body,
                noteID: try note.requireID(),
                attachmentType: note.attachmentType,
                attachmentID: note.attachmentID
            )
        }
    }
}
