import Vapor
import Fluent
import Foundation

struct GalleryWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("gallery", "data", ":key") { req async throws -> Response in
            guard let key = req.parameters.get("key", as: String.self) else {
                throw Abort(.badRequest, reason: "Invalid image key")
            }
            guard let service = req.application.imageService else {
                throw Abort(.internalServerError, reason: "Image service not configured")
            }
            
            let image = try await service.image(for: key)
            let res = Response(status: .ok, body: .init(data: image))
            res.headers.contentType = try await service.contentType(for: key).httpType
            res.headers.replaceOrAdd(name: .contentLength, value: "\(image.count)")
            
            let etag = SHA256.hash(data: image).compactMap { String(format: "%02x", $0) }.joined()
            if req.headers.first(name: .ifNoneMatch) == etag {
                return Response(status: .notModified)
            }
            res.headers.replaceOrAdd(name: .eTag, value: etag)
            res.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=31536000, immutable")
            
            return res
        }
    }
}
