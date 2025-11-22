import Vapor
import Fluent
import Foundation
import Core

struct GalleryWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        routes.get("gallery", "data", ":key", use: fetchResource)
                
        routes.get("gallery", page: .gallery)
        
        routes.get("gallery", ":imageID", page: .image)
        routes.get("gallery", ":imageID", "edit", page: .imageEditor)
        routes.post("gallery", ":imageID", "edit", use: editImage)
        routes.post("gallery", ":imageID", "delete", use: deleteImage)
        
        routes.grouped("gallery")
            .on(.POST, body: .collect(maxSize: "10mb"), use: upload)
    }
    
    @Sendable
    private func deleteImage(_ request: Request) async throws -> Response {
        guard let imageID = request.parameters.get("imageID", as: ImageID.self) else {
            throw Abort(.badRequest, reason: "Missing image ID")
        }
        
        do {
            guard let csrf = try? request.content.get(String.self, at: "_csrf"),
                  csrf == request.session.data["csrf.image-editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }
            try await request.commands.gallery.delete(imageID)
            return request.redirect(to: "/gallery")
        } catch {
            return try await recoverEditor(
                error: error,
                imageID: imageID,
                request: request
            )
        }
    }
    
    @Sendable
    private func editImage(_ request: Request) async throws -> Response {
        guard let imageID = request.parameters.get("imageID", as: ImageID.self) else {
            throw Abort(.badRequest, reason: "Missing image ID")
        }
        do {
            let payload = try request.content.decode(ImageEditPayload.self)
            guard let submittedCSRF = payload._csrf, submittedCSRF == request.session.data["csrf.image-editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }
            let input = EditImageInput(imageID: imageID, alt: payload.alt)
            _ = try await request.commands.gallery.edit(input)
            request.session.data["csrf.image-editor"] = nil
            return request.redirect(to: "/gallery/\(imageID)")
        } catch {
            return try await recoverEditor(
                error: error,
                imageID: imageID,
                request: request
            )
        }
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
        let alt = image.alt ?? image.key
        return Response(markdown: "![\(alt)](\(req.baseURL)/gallery/data/\(image.key))")
    }
    
    @Sendable
    private func recoverEditor(
        error: Error,
        imageID: ImageID,
        request: Request
    ) async throws -> Response {
        let image = try await request.commands.gallery.fetch(imageID, for: .write)
        let model = ImageEditorViewModel(
            _csrf: UUID().uuidString,
            error: error.localizedDescription,
            image: ImageViewModel(
                imageID: imageID,
                image: image,
                baseURL: request.baseURL
            ),
            submit: Form.Submit(
                action: "/gallery/\(imageID)/edit",
                label: "Save"
            )
        )
        let view = try await Template.imageEditor.render(model, with: request.view)
        let response = try await view.encodeResponse(for: request)
        request.session.data["csrf.image-editor"] = model._csrf
        return response
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
