import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditImageInput {
    
    let imageID: ImageID
    
    let alt: String?
}

struct EditImageCommand: Command {
    
    typealias Input = EditImageInput
    
    typealias Output = Image

    private let database: Database
    
    private let logger: Logger
        
    private let permission: AuthPermissionResolver<Image>
    
    private let storage: ImageService

    init(
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Image>,
        storage: ImageService
    ) {
        self.database = database
        self.logger = logger
        self.permission = permission
        self.storage = storage
    }

    func execute(_ input: Input) async throws -> Image {
        guard let image = try await Image.find(input.imageID, on: database) else {
            throw Abort(.notFound, reason: "Image not found")
        }
        try await permission.grant(image)
        image.alt = input.alt
        try await image.save(on: database)
        return image
    }
}

extension CommandFactory<EditImageInput, Image> {

    static var editImage: Self {
        CommandFactory { request in
            EditImageCommand(
                database: request.commandDB,
                logger: request.application.logger,
                permission: request.permissions.gallery.edit,
                storage: request.application.imageService!
            )
            .logged(logger: request.logger)
        }
    }
}
