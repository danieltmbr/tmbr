import Fluent
import Vapor

func apiRoutes(_ app: Application) throws {
    // Group all API routes under /api/posts
    let postsRoute = app.grouped("api", "posts")
    
    let protectedRoutes = postsRoute.grouped(AppleSignInAuthenticator())
    
    // GET /api/posts
    postsRoute.get { req async throws -> [Post] in
        try await Post.query(on: req.db).all()
    }
    
    // GET /api/posts/:postID
    postsRoute.get(":postID") { req async throws -> Post in
        guard let postID = req.parameters.get("postID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        return post
    }
    
    
    // POST /api/posts
    protectedRoutes.post { req async throws -> Post in
        // Expect a JSON payload matching the Post model
        let post = try req.content.decode(Post.self)
        try await post.save(on: req.db)
        return post
    }
    
    // PUT /api/posts/:postID
    protectedRoutes.put(":postID") { req async throws -> Post in
        guard let postID = req.parameters.get("postID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        let updatedData = try req.content.decode(Post.self)
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        // Update the fields (you may want to be selective here)
        post.title = updatedData.title
        post.content = updatedData.content
        // Optionally update other fields as necessary
        try await post.save(on: req.db)
        return post
    }
    
    // DELETE /api/posts/:postID
    protectedRoutes.delete(":postID") { req async throws -> HTTPStatus in
        guard let postID = req.parameters.get("postID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid post ID")
        }
        guard let post = try await Post.find(postID, on: req.db) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        try await post.delete(on: req.db)
        return .noContent
    }
}
