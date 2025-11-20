import Vapor
import Fluent
import Foundation
import Core

struct GalleryWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        // TODO: Add Gallery pages
        // Details & Edit & Delete images
        
        routes.get("gallery", "data", ":key", use: fetchResource)
        
        routes.get("gallery", page: .gallery)
        
        routes.grouped("gallery")
            .on(.POST, body: .collect(maxSize: "10mb"), use: upload)
    }
    
    @Sendable
    private func fetchResource(_ req: Request) async throws -> Response {
        guard let key = req.parameters.get("key", as: String.self) else {
            throw Abort(.badRequest, reason: "Invalid image key")
        }
        let resource = try await req.commands.gallery.resource(key)
        
        let res = Response(status: .ok, body: .init(data: resource.data))
        res.headers.contentType = resource.mediaType
        res.headers.replaceOrAdd(
            name: .contentLength,
            value: "\(resource.contentLenght)"
        )
        
        let etag = SHA256.hash(data: resource.data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        if req.headers.first(name: .ifNoneMatch) == etag {
            return Response(status: .notModified)
        }
        
        res.headers.replaceOrAdd(name: .eTag, value: etag)
        res.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=31536000, immutable")
        
        return res
    }

    @Sendable
    private func upload(_ req: Request) async throws -> Response {
        let payload = try req.content.decode(ImageUploadPayload.self)
        let image = try await req.commands.gallery.add(payload)
        let alt = image.alt ?? image.name
        return Response(markdown: "![\(alt)](\(req.baseURL)/gallery/data/\(image.name))")
    }
}

extension Response {
    convenience init(markdown: String) {
        self.init(status: .ok)
        headers.contentType = .plainText
        body = Body(string: markdown)
    }
}

extension Request {
    var baseURL: String {
        let proto = headers["X-Forwarded-Proto"].first ?? "https"
        guard let host = headers.first(name: .host) else {
            return "\(proto)://localhost"
        }
        return "\(proto)://\(host)"
    }
}
