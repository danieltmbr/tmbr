import Foundation
import WebCore
import TmbrCore
import Vapor

struct QuoteItemViewModel: Encodable, Sendable {
    private let id: String
    private let body: String
    private let sourceTitle: String
    private let sourceSubtitle: String?
    private let sourceType: String?
    private let sourceURL: String
    private let imageURL: String?

    init(quote: QuoteResponse) {
        let src = quote.source
        id = quote.id.uuidString
        body = MarkdownFormatter.html(citationPlacement: .inline).format(quote.body)
        sourceTitle = src.title
        sourceSubtitle = src.subtitle
        sourceType = src.type
        imageURL = src.preview?.image?.thumbnailUrl
        switch src.kind {
        case .note:
            sourceURL = src.preview?.id.map { "/catalogue/item/\($0)" } ?? "/catalogue"
        case .post:
            sourceURL = src.postID.map { "/posts/\($0)" } ?? "/posts"
        }
    }
}

struct QuoteRandomViewModel: Encodable, Sendable {
    private let quote: QuoteItemViewModel?
    private let isShareable: Bool

    init(quote: QuoteResponse?, isShareable: Bool = true) {
        self.quote = quote.map(QuoteItemViewModel.init)
        self.isShareable = isShareable
    }
}

extension Template where Model == QuoteRandomViewModel {
    static let quote = Template(name: "Quotes/quote")
}

extension Page {
    static var randomQuote: Self {
        Page(template: .quote) { req in
            let quote = try? await req.commands.quotes.random(QuoteQueryPayload())
            let quoteResponse = try quote.map { try QuoteResponse(quote: $0, baseURL: req.baseURL) }
            return QuoteRandomViewModel(quote: quoteResponse)
        }
    }

    static var quote: Self {
        Page(template: .quote) { req in
            guard let quoteID = req.parameters.get("quoteID", as: UUID.self) else {
                throw Abort(.badRequest, reason: "Invalid quote ID")
            }
            let quote = try await req.commands.quotes.fetch(quoteID)
            let quoteResponse = try QuoteResponse(quote: quote, baseURL: req.baseURL)
            // Permalink page: the URL is already the shareable link, no share button needed.
            return QuoteRandomViewModel(quote: quoteResponse, isShareable: false)
        }
    }
}
