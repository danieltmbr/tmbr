import Vapor

struct QuotesWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("quotes", page: .quotesList)
        routes.get("quotes", "random", page: .randomQuote)
        routes.get("quotes", ":quoteID", page: .quote)
    }
}
