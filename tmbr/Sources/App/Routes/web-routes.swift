import Fluent
import Vapor

func webRoutes(_ app: Application) throws {
    let protected = app.grouped(User.redirectMiddleware(path: "/signin"))
    
    app.get { req async throws -> View in
        let posts = try await Post.query(on: req.db)
            .filter(\.$state == .published)
            .sort(\.$createdAt, .descending)
            .all()
        return try await req.view.render("posts", PostsViewModel(posts: posts))
    }
    
    protected.get("drafts") { req async throws -> View in
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let posts = try await Post.query(on: req.db)
            .filter(\.$state == .draft)
            .filter(\.$author.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()
        return try await req.view.render("posts", PostsViewModel(posts: posts))
    }

    app.get("post", ":postID") { req async throws -> View in
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound)
        }
        guard post.state == .published || post.$author.id == req.auth.get(User.self)?.id else {
            req.logger.trace("Unauthorized. Draft posts are only available for the author.")
            throw Abort(.notFound, reason: "Post not found")
        }
        return try await req.view.render("post", PostViewModel(post: post))
    }
    
    app.get("signin") { req async throws -> View in
        struct ViewContext: Encodable {
            let clientId: String
            let scope: String = "name email"
            let redirectUrl: String
            let state: String
            let popup: Bool = false
        }

        let state = [UInt8].random(count: 16).base64
        req.session.data["state"] = state
        
        let context = ViewContext(
            clientId: Environment.signIn.appID,
            redirectUrl: Environment.signIn.redirectUrl,
            state: state
        )
        return try await req.view.render("signin", context)
    }
    
    app.get("notifications") { req async throws -> View in
        try await req.view.render("notifications")
    }
    
    app.get("manifest.json") { req async throws -> Response in
        struct ViewModel: Encodable {
            let name: String
            let startURL: String
        }
        let model = ViewModel(
            name: Environment.webApp.appName,
            startURL: Environment.webApp.startURL
        )
        let view: View = try await req.view.render("manifest", model)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(
            name: .contentType,
            value: "application/manifest+json; charset=utf-8"
        )
        return Response(
            status: .ok,
            headers: headers,
            body: Response.Body(buffer: view.data)
        )
    }
}
