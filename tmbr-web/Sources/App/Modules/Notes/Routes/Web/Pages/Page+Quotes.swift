import Foundation
import WebCore
import TmbrCore

struct QuoteItemViewModel: Encodable, Sendable {
    private let id: String
    private let body: String
    private let citation: String?
    private let sourceTitle: String
    private let sourceSubtitle: String?
    private let sourceType: String?
    private let sourceURL: String
    private let imageURL: String?

    init(quote: QuoteResponse) {
        let src = quote.source
        id = quote.id.uuidString
        let (bodyMarkdown, citationText) = Self.splitCitation(from: quote.body)
        body = MarkdownFormatter.html.format(bodyMarkdown)
        citation = citationText
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

    // Separates `^[citation text](cite: kind)` lines from the quote body so they can be
    // rendered outside the <blockquote> element.
    private static func splitCitation(from markdown: String) -> (body: String, citation: String?) {
        var bodyLines: [String] = []
        var citation: String? = nil

        for line in markdown.components(separatedBy: "\n") {
            if line.hasPrefix("^["), citation == nil {
                let rest = line.dropFirst(2)
                if let end = rest.firstIndex(of: "]") {
                    citation = String(rest[rest.startIndex..<end])
                }
            } else {
                bodyLines.append(line)
            }
        }

        return (
            body: bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines),
            citation: citation
        )
    }
}

struct QuoteRandomViewModel: Encodable, Sendable {
    private let quote: QuoteItemViewModel?

    init(quote: QuoteResponse?) {
        self.quote = quote.map(QuoteItemViewModel.init)
    }
}

struct QuotesListViewModel: Encodable, Sendable {
    private let quotes: [QuoteItemViewModel]
    private let panels: [FilterPanelViewModel]
    private let term: String?

    init(quotes: [QuoteResponse], panels: [FilterPanelViewModel], term: String?) {
        self.quotes = quotes.map(QuoteItemViewModel.init)
        self.panels = panels
        self.term = term
    }
}

extension Template where Model == QuoteRandomViewModel {
    static let randomQuote = Template(name: "Quotes/quote")
}

extension Template where Model == QuotesListViewModel {
    static let quotesList = Template(name: "Quotes/quotes")
}

extension Page {
    static var randomQuote: Self {
        Page(template: .randomQuote) { req in
            let quote = try? await req.commands.quotes.random(QuoteQueryPayload())
            let quoteResponse = try quote.map { try QuoteResponse(quote: $0, baseURL: req.baseURL) }
            return QuoteRandomViewModel(quote: quoteResponse)
        }
    }

    static var quotesList: Self {
        Page(template: .quotesList) { req in
            let payload = try req.query.decode(CatalogueQueryPayload.self)
            let allCategories = try await req.commands.catalogueCategories.list()
            let mapper = CatalogueQueryMapper(categories: allCategories)
            let input = mapper.toQuoteQuery(from: payload)
            let quotes: [Quote] = payload.term != nil
                ? try await req.commands.quotes.search(input)
                : try await req.commands.quotes.list(input)
            let baseURL = req.baseURL
            let responses = try quotes.map { try QuoteResponse(quote: $0, baseURL: baseURL) }
            let typeItems = allCategories
                .filter { $0.parentSlug == nil }
                .map { cat in
                    FilterItemViewModel(
                        icon: cat.icon ?? "link",
                        label: cat.name,
                        value: cat.slug
                    ).check(payload.types?.contains(cat.slug) ?? true)
                }
            return QuotesListViewModel(
                quotes: responses,
                panels: [.types(typeItems)],
                term: payload.term
            )
        }
    }
}
