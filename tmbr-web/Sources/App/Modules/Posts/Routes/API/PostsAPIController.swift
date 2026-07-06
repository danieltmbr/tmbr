import Vapor
import WebAuth
import Fluent
import WebCore
import TmbrCore
import Foundation

struct PostsAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // Group all API routes under /api/posts
        let postsRoute = routes.grouped("api", "posts")
        let protectedRoutes = postsRoute

        // GET /api/posts — paginated list, or text search when ?term= is present.
        // With ?term=: searches title and body (unpaginated, nextCursor always nil).
        // Without ?term=: cursor-paginated list, supports ?since=&cursor=&limit=.
        // Language filtering uses the request's Accept-Language preference in both paths.
        postsRoute.get { req async throws -> PageResult<PostResponse> in
            let baseURL = req.baseURL
            if let term = try? req.query.get(String.self, at: "term"),
               !term.trimmingCharacters(in: .whitespaces).isEmpty {
                let posts = try await req.commands.posts.list(
                    ListPostsInput(query: PostQueryPayload(term: term), page: nil)
                )
                return PageResult(items: try posts.map { try PostResponse(post: $0, baseURL: baseURL) })
            }
            let pageQuery = try req.query.decode(PageQuery.self)
            let page = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
            let posts = try await req.commands.posts.list(
                ListPostsInput(query: PostQueryPayload(term: nil), page: page)
            )
            return try PageResult(from: posts, limit: page.limit) { try PostResponse(post: $0, baseURL: baseURL) }
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
