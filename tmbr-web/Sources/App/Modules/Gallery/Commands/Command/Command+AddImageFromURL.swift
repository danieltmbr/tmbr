import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth

/// Downloads an image from an external URL, validates its content type, stores the file
/// (plus thumbnail), and saves an `Image` record with `sourceURL` set for deduplication.
/// If the database save fails, stored files are deleted to prevent orphaned data.
struct AddImageFromURLCommand: Command {

    typealias Input = ImageURLPayload

    typealias Output = Image

    private let client: Client

    private let database: Database

    private let logger: Logger

    private let permission: AuthPermissionResolver<Void>

    private let storage: ImageService

    init(
        client: Client,
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Void>,
        storage: ImageService
    ) {
        self.client = client
        self.database = database
        self.logger = logger
        self.permission = permission
        self.storage = storage
    }

    func execute(_ payload: ImageURLPayload) async throws -> Image {
        let user = try await permission.grant()

        guard let url = URL(string: payload.url) else {
            throw Abort(.badRequest, reason: "Invalid image URL")
        }

        let response = try await client.get(URI(string: url.absoluteString))

        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Image fetch failed. Upstream returned \(response.status.code)")
        }

        guard let body = response.body,
              let data = body.getData(at: 0, length: body.readableBytes) else {
            throw Abort(.badGateway, reason: "Image fetch failed. Response body is empty")
        }

        let contentType = try resolveContentType(from: response)

        let meta = try await storage.store(data: data, contentType: contentType)

        let image = Image(
            alt: payload.alt,
            key: meta.key,
            thumbnailKey: meta.thumbnailKey,
            size: meta.size,
            ownerID: user.id!,
            sourceURL: payload.url
        )

        do {
            try await image.save(on: database)
        } catch {
            try await storage.delete(meta.key)
            try await storage.delete(meta.thumbnailKey)
            throw error
        }

        return image
    }

    private func resolveContentType(from response: ClientResponse) throws -> MediaContentType {
        guard let httpMediaType = response.headers.contentType else {
            throw Abort(.unsupportedMediaType, reason: "Missing content type in response")
        }

        let knownTypes: [MediaContentType] = [.png, .jpeg, .webp, .gif, .svg]
        guard let mediaType = knownTypes.first(where: { $0.httpType == httpMediaType }) else {
            throw Abort(.unsupportedMediaType, reason: "Unsupported image content type: \(httpMediaType.serialize())")
        }

        return mediaType
    }
}

extension CommandFactory<ImageURLPayload, Image> {

    static var addImageFromURL: Self {
        CommandFactory { request in
            AddImageFromURLCommand(
                client: request.client,
                database: request.commandDB,
                logger: request.application.logger,
                permission: request.permissions.gallery.create,
                storage: request.application.imageService!
            )
            .logged(logger: request.logger)
        }
    }
}
