import Vapor
import Fluent
import Foundation
import WebAuth
import PostgresKit
import WebCore
import TmbrCore

struct QuotesAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let quotes = routes.grouped("api", "quotes")
        quotes.get(use: list)
        quotes.get("random", use: random)
        quotes.get("search", use: search)
    }

    @Sendable
    private func list(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quotes = try await request.commands.quotes.list(payload)
        return try quotes.map { try QuoteResponse(quote: $0, baseURL: request.baseURL) }
    }

    @Sendable
    private func random(request: Request) async throws -> QuoteResponse {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quote = try await request.commands.quotes.random(payload)
        return try QuoteResponse(quote: quote, baseURL: request.baseURL)
    }

    @Sendable
    private func search(request: Request) async throws -> [QuoteResponse] {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quotes = try await request.commands.quotes.search(payload)
        return try quotes.map { try QuoteResponse(quote: $0, baseURL: request.baseURL) }
    }
}
