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
            return try await req.commands.posts.fetch(postID, for: .read)
        }
        
        // POST /api/posts
        protectedRoutes.post { req async throws -> Post in
            let post = try req.content.decode(PostPayload.self)
            return try await req.commands.posts.create(post)
        }
        
        // PUT /api/posts/:postID
        protectedRoutes.put(":postID") { req async throws -> Post in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid post ID")
            }
            let payload = try req.content.decode(PostPayload.self)
            let editPayload = payload.edit(id: postID)
            return try await req.commands.posts.edit(editPayload)
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
