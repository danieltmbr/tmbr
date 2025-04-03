import Fluent
import Vapor

func apiRoutes(_ app: Application) throws {
    // Group all API routes under /api/posts
    let postsRoute = app.grouped("api", "posts")
    
    let protectedRoutes = postsRoute.grouped(AppleSignInAuthenticator())
    
    // GET /api/posts
    postsRoute.get { req async throws -> [Post] in
        try await Post.query(on: req.db)
            .filter(\.$state == .published)
            .with(\.$author)
            .all()
    }
    
    // GET /api/posts/:postID
    postsRoute.get(":postID") { req async throws -> Post in
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        guard post.state == .published || post.$author.id == req.auth.get(User.self)?.id else {
            req.logger.trace("Unauthorized. Draft posts are only available for the author.")
            throw Abort(.notFound, reason: "Post not found")
        }
        return post
    }
    
    
    // POST /api/posts
    protectedRoutes.post { req async throws -> Post in
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        let post = try req.content.decode(Post.self)
        post.$author.id = try user.requireID()
        try await post.save(on: req.db)
        return post
    }
    
    // PUT /api/posts/:postID
    protectedRoutes.put(":postID") { req async throws -> Post in
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        guard user.id == post.$author.id else {
            throw Abort(.forbidden, reason: "You are not allowed to update this post")
        }
        let updatedData = try req.content.decode(Post.self)
        post.title = updatedData.title
        post.content = updatedData.content
        post.state = updatedData.state
        try await post.save(on: req.db)
        return post
    }
    
    // DELETE /api/posts/:postID
    protectedRoutes.delete(":postID") { req async throws -> HTTPStatus in
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        guard user.id == post.$author.id else {
            throw Abort(.forbidden, reason: "You are not allowed to delete this post")
        }
        try await post.delete(on: req.db)
        return .noContent
    }
}
