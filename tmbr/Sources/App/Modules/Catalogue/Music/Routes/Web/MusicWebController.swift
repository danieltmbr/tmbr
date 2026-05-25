import Vapor
import Core

struct MusicWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.grouped("music")
            .grouped(RecoverMiddleware())
            .get(page: .music)
    }
}
