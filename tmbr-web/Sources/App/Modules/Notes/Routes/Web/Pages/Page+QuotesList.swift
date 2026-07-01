import Foundation
import WebCore
import TmbrCore
import Vapor

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

extension Template where Model == QuotesListViewModel {
    static let quotesList = Template(name: "Quotes/quotes")
}

extension Page {
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
