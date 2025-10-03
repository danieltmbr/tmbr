import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("signin", page: .signin)
    }
}
