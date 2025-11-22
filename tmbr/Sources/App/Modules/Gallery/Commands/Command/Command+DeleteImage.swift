import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ImageID, Void> {
    static func deleteImage(
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Image>,
        storage: ImageService
    ) -> Self {
        PlainCommand { imageID in
            guard let image = try await Image.find(imageID, on: database) else {
                throw Abort(.notFound, reason: "Image not found")
            }
            try await permission.grant(image)
            try await image.delete(on: database)
            do {
                try await storage.delete(image.key)
                if image.thumbnailKey != image.key {
                    try await storage.delete(image.thumbnailKey)
                }
            } catch {
                logger.error("Image resources hasn't been properly cleared from storage: \(error.localizedDescription)")
            }
        }
    }
}

extension CommandFactory<ImageID, Void> {
    
    static var deleteImage: Self {
        CommandFactory { request in
            .deleteImage(
                database: request.db,
                logger: request.logger,
                permission: request.permissions.gallery.delete,
                storage: request.application.imageService!
            )
            .logged(name: "Delete Image", logger: request.logger)
        }
    }
}
