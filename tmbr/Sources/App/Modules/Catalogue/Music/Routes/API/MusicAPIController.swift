import Vapor
import Core

struct MusicAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let musicRoute = routes.grouped("api", "music")

        // GET /api/music?term=...
        musicRoute.get { request async throws -> [PreviewResponse] in
            let term = try? request.query.get(String.self, at: "term")
            let result = try await request.commands.music.search(term)
            let baseURL = request.baseURL
            return result.previews.map { PreviewResponse(preview: $0, baseURL: baseURL) }
                + result.noteMatches.map { PreviewResponse(preview: $0, baseURL: baseURL) }
        }
    }
}
