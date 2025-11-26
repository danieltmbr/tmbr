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
            authorID: try user.requireID(),
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
