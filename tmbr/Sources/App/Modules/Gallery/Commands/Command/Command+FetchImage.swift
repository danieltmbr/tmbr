import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchImageCommand: Command {
    
    typealias PermissionInput = (image: Image, reason: FetchReason)
    
    typealias Input = FetchParameters<ImageID>
    
    typealias Output = Image
    
    private let database: Database
    
    private let logger: Logger
    
    private let permission: ErasedPermissionResolver<PermissionInput>
    
    init(
        database: Database,
        logger: Logger,
        permission: ErasedPermissionResolver<PermissionInput>
    ) {
        self.database = database
        self.logger = logger
        self.permission = permission
    }
    
    init(
        database: Database,
        logger: Logger,
        readPermission: AuthPermissionResolver<Image>,
        writePermission: AuthPermissionResolver<Image>
    ) {
        self.init(
            database: database,
            logger: logger,
            permission: ErasedPermissionResolver(input: \.image, condition: \.reason) { reason in
                switch reason {
                case .read: readPermission.eraseOutput()
                case .write: writePermission.eraseOutput()
                }
            }
        )
    }
    
    func execute(_ params: FetchParameters<ImageID>) async throws -> Image {
        guard let image = try await Image.find(params.itemID, on: database) else {
            throw Abort(.notFound, reason: "Image not found")
        }
        try await permission.grant((image, params.reason))
        return image
    }
}

extension CommandFactory<FetchParameters<ImageID>, Image> {
    
    static var fetchImage: Self {
        CommandFactory { request in
            FetchImageCommand(
                database: request.commandDB,
                logger: request.application.logger,
                readPermission: request.permissions.gallery.access,
                writePermission: request.permissions.gallery.edit
            )
            .logged(logger: request.logger)
        }
    }
}
