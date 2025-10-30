import Vapor
import Fluent

struct PostsAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // Group all API routes under /api/posts
        let postsRoute = routes.grouped("api", "posts")
        
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
            try await req.permissions.posts.access(post)
            return post
        }
        
        // POST /api/posts
        protectedRoutes.post { req async throws -> Post in
            try await req.permissions.posts.create()
            let post = try req.content.decode(Post.self)
            post.$author.id = try req.auth.require(User.self).requireID()
            try await post.save(on: req.db)
            
            Task.detached {
                let notificationService = req.application.notificationService
                try await notificationService?.notify(
                    subscriptions: WebPushSubscription.query(on: req.db).all(),
                    content: PushNotification(post: post)
                )
            }
            
            return post
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
            guard let post = try await Post.find(postID, on: req.db) else {
                throw Abort(.notFound, reason: "Post not found")
            }
            try await req.permissions.posts.delete(post)
            try await post.delete(on: req.db)
            return .noContent
        }
    }
}
