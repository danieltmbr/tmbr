import Vapor
import Core

struct PreviewsWebController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes
            .grouped(RecoverMiddleware())
            .get("catalogue", "item", ":previewID", page: .catalogueItem)
    }
}
