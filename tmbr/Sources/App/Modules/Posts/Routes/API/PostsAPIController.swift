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
    
        // DELETE /api/posts/media/:mediaID
        protectedRoutes.post("media", ":mediaID", use: createFromMedia)
    }
    
    struct AssemblePostRequest: Content, Sendable {
        var title: String
        var includeNotes: Bool? // default true
        var noteTypes: [MediaNote.NoteType]? // default both
        var stateFilter: MediaNote.State? // default published
    }
    
    func createFromMedia(req: Request) async throws -> Post {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.unauthorized)
        }
        guard let mediaID = req.parameters.get("mediaID", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(AssemblePostRequest.self)
        
        guard let media = try await Media.find(mediaID, on: req.db) else { throw Abort(.notFound) }
        try await media.$notes.load(on: req.db)
        
        // Filter notes
        let includeNotes = input.includeNotes ?? true
        let allowedTypes = Set(input.noteTypes ?? [ .quote, .note ])
        let allowedState = input.stateFilter ?? .published
        let notes = includeNotes ? media.notes.filter { allowedTypes.contains($0.type) && $0.state == allowedState } : []
        
        // Compose body (simple Markdown for now)
        var body = "# \(media.preview.title)\n\n"
        if let subtitle = media.preview.subtitle { body += "**\(subtitle)**\n\n" }
        if let desc = media.preview.body { body += "\(desc)\n\n" }
        if let img = media.preview.imageURL { body += "![image](\(img))\n\n" }
        
        if !notes.isEmpty {
            body += "## Notes\n\n"
            for n in notes {
                switch n.type {
                case .quote:
                    body += "> \(n.text)\n\n"
                case .note:
                    body += "- \(n.text)\n"
                }
                if let c = n.commentary { body += "  \n  _\(c)_\n" }
            }
        }
        
        // Save post
        let post = Post(
            author: user,
            content: body,
            createdAt: .now,
            state: .published,
            title: media.preview.title
        )
        post.$media.id = mediaID
        try await post.save(on: req.db)
        return post
    }
}
