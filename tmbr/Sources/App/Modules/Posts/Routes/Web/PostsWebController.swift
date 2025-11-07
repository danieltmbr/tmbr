import Vapor
import Fluent
import AuthKit

struct PostsWebController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(page: .posts)
        routes.get("post", ":postID", page: .post)

        let protected = routes.grouped(
            User.redirectMiddleware(path: "/signin")
        )
        protected.get("drafts", page: .drafts)
    }
}
