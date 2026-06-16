import Vapor
import Fluent
import Foundation
import CoreAuth
import CoreTmbr

struct GalleryAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {        
        let galleryRoute = routes.grouped("api", "gallery")
        
        galleryRoute.get("images") { req async throws -> [ImageResponse] in
            let images = try await req.commands.gallery.list()
            return images.map { makeResponse(from: $0, req: req) }
        }
        
        galleryRoute.get("images", ":id") { req async throws -> ImageResponse in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id.")
            }
            let image = try await req.commands.gallery.fetch(id, for: .read)
            return makeResponse(from: image, req: req)
        }

        galleryRoute.on(.POST, "images", body: .collect(maxSize: "10mb")) { req async throws -> ImageResponse in
            let payload = try req.content.decode(ImageUploadPayload.self)
            let image = try await req.commands.gallery.add(payload)
            return makeResponse(from: image, req: req)
        }
        
        galleryRoute.put("images", ":id") { req async throws -> ImageResponse in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id.")
            }
            let payload = try req.content.decode(ImageEditPayload.self)
            let input = EditImageCommand.Input(imageID: id, alt: payload.alt)
            let image = try await req.commands.gallery.edit(input)
            return makeResponse(from: image, req: req)
        }
        
        galleryRoute.delete("images", ":id") { req async throws -> HTTPStatus in
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid image id.")
            }
            try await req.commands.gallery.delete(id)
            return .noContent
        }

        galleryRoute.post("images", "from-url") { req async throws -> ImageResponse in
            let payload = try req.content.decode(ImageURLPayload.self)
            let image = try await req.commands.gallery.addFromURL(payload)
            return makeResponse(from: image, req: req)
        }

        galleryRoute.get("images", "lookup") { req async throws -> ImageResponse in
            guard let url = req.query[String.self, at: "url"] else {
                throw Abort(.badRequest, reason: "Missing url query parameter")
            }
            guard let image = try await req.commands.gallery.lookup(url) else {
                throw Abort(.notFound)
            }
            return makeResponse(from: image, req: req)
        }
    }
    
    @Sendable
    private func makeResponse(from image: Image, req: Request) -> ImageResponse {
        ImageResponse(
            id: image.id,
            alt: image.alt,
            url: absoluteURL(for: image.key, on: req),
            thumbnailUrl: absoluteURL(for: image.thumbnailKey, on: req),
            size: ImageSize(width: Double(image.size.width), height: Double(image.size.height)),
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
