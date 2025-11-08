import Vapor
import AuthKit
import Fluent
import Core

struct PostsAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // Group all API routes under /api/posts
        let postsRoute = routes.grouped("api", "posts")
        
        let protectedRoutes = postsRoute.grouped(AppleSignInAuthenticator())
        
        // GET /api/posts
        postsRoute.get { req async throws -> [Post] in
            try await req.commands.posts.list()
        }
        
        // GET /api/posts/:postID
        postsRoute.get(":postID") { req async throws -> Post in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid post ID")
            }
             return try await req.commands.posts.post(postID)
        }
        
        // POST /api/posts
        protectedRoutes.post { req async throws -> Post in
            let post = try req.content.decode(Post.self)
             return try await req.commands.posts.create(post)
        }
        
        // PUT /api/posts/:postID
        protectedRoutes.put(":postID") { req async throws -> Post in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid post ID")
            }
            guard let post = try await Post.find(postID, on: req.db) else {
                throw Abort(.notFound, reason: "Post not found")
            }
            try await req.permissions.posts.edit(post)
            
            let updatedData = try req.content.decode(Post.self)
            post.title = updatedData.title
            post.content = updatedData.content
            post.state = updatedData.state
            try await post.save(on: req.db)
            return post
        }
        
        // DELETE /api/posts/:postID
        protectedRoutes.delete(":postID") { req async throws -> HTTPStatus in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid post ID")
            }
            try await req.commands.posts.delete(postID)
            return .noContent
        }
    }
}
