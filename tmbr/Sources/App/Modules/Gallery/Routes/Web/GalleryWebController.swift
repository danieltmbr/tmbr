import Vapor
import Fluent
import Foundation

struct GalleryWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        // TODO: Add Gallery pages
        // - List images
        // - Upload Form & Delete images
        
        routes.get("gallery", "data", ":key", use: fetchResource)
        
        routes.grouped("gallery", "upload")
            .on(.POST, body: .collect(maxSize: "10mb"), use: upload)
        
        // routes.get("gallery", "list", use: list)
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
        return Response(markdown: "![\(alt)](/gallery/data/\(image.name))")
    }

//    @Sendable
//    private func list(_ req: Request) async throws -> Response {
//        let items = try await req.commands.gallery.list()
//        // Expect each item to have a markdown representation. Join by newline for easy paste.
//        let markdown = items.map { item in
//            if let mdProvider = item as? Commands.Gallery.MarkdownRepresentable {
//                return mdProvider.markdown
//            }
//            // Fallback: attempt to construct markdown if keys are present
//            if let dict = item as? [String: Any], let key = dict["key"] as? String {
//                return "![alt text](/gallery/data/\(key))"
//            }
//            return ""
//        }.filter { !$0.isEmpty }.joined(separator: "\n")
//
//        var res = Response(status: .ok)
//        res.headers.contentType = .plainText
//        res.body = .init(string: markdown)
//        return res
//    }
}

extension Response {
    convenience init(markdown: String) {
        self.init(status: .ok)
        headers.contentType = .plainText
        body = Body(string: markdown)
    }
}
