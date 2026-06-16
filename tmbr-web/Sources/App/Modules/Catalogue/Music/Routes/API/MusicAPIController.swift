import Vapor
import CoreWeb
import CoreTmbr

struct MusicAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let musicRoute = routes.grouped("api", "music")

        // GET /api/music?term=...
        musicRoute.get { request async throws -> [PreviewResponse] in
            let payload = try request.query.decode(CatalogueQueryPayload.self)
            let result = try await request.commands.music.search(payload)
            let baseURL = request.baseURL
            return result.previews.map { PreviewResponse(preview: $0, baseURL: baseURL) }
                + result.noteMatches.map { PreviewResponse(preview: $0, baseURL: baseURL, isNoteMatch: true) }
        }
    }
}
