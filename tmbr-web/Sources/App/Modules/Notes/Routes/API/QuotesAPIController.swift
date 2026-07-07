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
        // GET /api/quotes — paginated list with optional ?term= text filter.
        // Supports ?since=&cursor=&limit= for pagination and ?term= for full-text search.
        // Both can be combined; source filtering uses the request's category/language preferences.
        quotes.get(use: list)
        quotes.get("random", use: random)
    }

    @Sendable
    private func list(request: Request) async throws -> PageResult<QuoteResponse> {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let pageQuery = try request.query.decode(PageQuery.self)
        let page = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
        let input = ListQuotesInput(payload: payload, page: page)
        let quotes = try await request.commands.quotes.list(input)
        let trimmed = Array(quotes.prefix(page.limit))
        let formatter = ISO8601DateFormatter()
        let nextCursor: String? = quotes.count > page.limit
            ? trimmed.last?.createdAt.map { formatter.string(from: $0) } ?? nil
            : nil
        let baseURL = request.baseURL
        return PageResult(
            items: try trimmed.map { try QuoteResponse(quote: $0, baseURL: baseURL) },
            nextCursor: nextCursor
        )
    }

    @Sendable
    private func random(request: Request) async throws -> QuoteResponse {
        let payload = try request.query.decode(QuoteQueryPayload.self)
        let quote = try await request.commands.quotes.random(payload)
        return try QuoteResponse(quote: quote, baseURL: request.baseURL)
    }
}
