import Vapor

struct QuotesWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("quotes", page: .randomQuote)
        routes.get("quotes", "list", page: .quotesList)
    }
}
