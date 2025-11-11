import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ImageID, Image> {
    static func fetchImage(
        database: Database,
        logger: Logger
    ) -> Self {
        PlainCommand { imageID in
            guard let image = try await Image.find(imageID, on: database) else {
                throw Abort(.notFound, reason: "Image not found")
            }
            return image
        }
    }
}

extension CommandFactory<ImageID, Image> {
    
    static var fetchImage: Self {
        CommandFactory { request in
            .fetchImage(
                database: request.db,
                logger: request.logger
            )
            .logged(name: "Fetch Image", logger: request.logger)
        }
    }
}
