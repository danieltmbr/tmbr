import Vapor
import Fluent
import Foundation
import AuthKit

struct GalleryAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // Group all API routes under /api/gallery
        
        let galleryRoute = routes.grouped("api", "gallery")
        let protectedRoutes = galleryRoute.grouped(AppleSignInAuthenticator())
        
        protectedRoutes.get("images") { req async throws -> [ImageResponse] in
            let images = try await Image.query(on: req.db)
                .sort(\.$uploadedAt, .descending)
                .all()
            return images.map { makeResponse(from: $0, req: req) }
        }
        
        protectedRoutes.get("images", ":id") { req async throws -> ImageResponse in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id")
            }
            guard let image = try await Image.find(id, on: req.db) else {
                throw Abort(.notFound)
            }
            return makeResponse(from: image, req: req)
        }

        protectedRoutes.on(.POST, "images", body: .collect(maxSize: "10mb")) { req async throws -> ImageResponse in
            guard let user = req.auth.get(User.self), user.role == .admin else {
                throw Abort(.unauthorized)
            }
            guard let service = req.application.imageService else {
                throw Abort(.internalServerError, reason: "Image service not configured")
            }
            let payload = try req.content.decode(ImageUploadPayload.self)
            let meta = try await service.store(image: payload.image)
            let image = Image(
                alt: payload.alt,
                name: meta.key,
                thumbnail: meta.thumbnailKey,
                size: meta.size
            )
            do {
                try await image.save(on: req.db)
            } catch {
                try await service.delete(meta.key)
                try await service.delete(meta.thumbnailKey)
                throw error
            }
            return makeResponse(from: image, req: req)
        }
        
        protectedRoutes.delete("images", ":id") { req async throws -> HTTPStatus in
            guard let user = req.auth.get(User.self), user.role == .admin else {
                throw Abort(.unauthorized)
            }
            guard let service = req.application.imageService else {
                throw Abort(.internalServerError, reason: "Image service not configured")
            }
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id")
            }
            guard let image = try await Image.find(id, on: req.db) else {
                throw Abort(.notFound)
            }
            
            try await image.delete(on: req.db)
            try await service.delete(image.name)
            if image.thumbnail != image.name {
                try await service.delete(image.thumbnail)
            }

            return .noContent
        }
    }
    
    @Sendable
    private func makeResponse(from image: Image, req: Request) -> ImageResponse {
        ImageResponse(
            id: image.id,
            alt: image.alt,
            url: absoluteURL(for: image.name, on: req),
            thumbnailUrl: absoluteURL(for: image.thumbnail, on: req),
            size: CGSize(width: image.size.width, height: image.size.height),
            uploadedAt: image.uploadedAt ?? .now
        )
    }
    
    private func absoluteURL(for imageName: String, on request: Request) -> String {
        let scheme = request.headers.first(name: .xForwardedProto)
            ?? request.url.scheme
            ?? (request.application.http.server.configuration.tlsConfiguration != nil ? "https" : "http")
        let host = request.headers.first(name: .xForwardedHost) 
            ?? request.headers.first(name: .host)
            ?? "localhost"
        return "\(scheme)://\(host)/gallery/data/\(imageName)"
    }
}
