import Vapor
import Fluent
import Foundation
import AuthKit

struct GalleryAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {        
        let galleryRoute = routes.grouped("api", "gallery")
        
        galleryRoute.get("images") { req async throws -> [ImageResponse] in
            let images = try await req.commands.gallery.list()
            return images.map { makeResponse(from: $0, req: req) }
        }
        
        galleryRoute.get("images", ":id") { req async throws -> ImageResponse in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id")
            }
            let image = try await req.commands.gallery.fetch(id)
            return makeResponse(from: image, req: req)
        }

        galleryRoute.on(.POST, "images", body: .collect(maxSize: "10mb")) { req async throws -> ImageResponse in
            let payload = try req.content.decode(ImageUploadPayload.self)
            let image = try await req.commands.gallery.add(payload)
            return makeResponse(from: image, req: req)
        }
        
        galleryRoute.delete("images", ":id") { req async throws -> HTTPStatus in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id")
            }
            try await req.commands.gallery.delete(id)
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
