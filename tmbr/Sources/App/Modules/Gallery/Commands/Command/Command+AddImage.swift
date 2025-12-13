import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct AddImageCommand: Command {
    
    typealias Input = ImageUploadPayload
    
    typealias Output = Image

    private let database: Database
    
    private let logger: Logger
        
    private let permission: AuthPermissionResolver<Void>
    
    private let storage: ImageService

    init(
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Void>,
        storage: ImageService
    ) {
        self.database = database
        self.logger = logger
        self.permission = permission
        self.storage = storage
    }

    func execute(_ payload: ImageUploadPayload) async throws -> Image {
        let user = try await permission.grant()
        let meta = try await storage.store(image: payload.image)
        let image = Image(
            alt: payload.alt,
            key: meta.key,
            thumbnailKey: meta.thumbnailKey,
            size: meta.size,
            ownerID: user.id!
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
}

extension CommandFactory<ImageUploadPayload, Image> {

    static var addImage: Self {
        CommandFactory { request in
            AddImageCommand(
                database: request.commandDB,
                logger: request.application.logger,
                permission: request.permissions.gallery.create,
                storage: request.application.imageService!
            )
            .logged(logger: request.logger)
        }
    }
}
