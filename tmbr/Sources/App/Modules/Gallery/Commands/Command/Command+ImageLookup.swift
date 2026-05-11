import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

/// Finds an existing gallery image by its original source URL.
/// Editors call this before `addFromURL` to avoid re-downloading the same image on repeated saves.
struct ImageLookupCommand: Command {

    typealias Input = String

    typealias Output = Image?

    private let database: Database

    private let logger: Logger

    private let permission: AuthPermissionResolver<Void>

    init(
        database: Database,
        logger: Logger,
        permission: AuthPermissionResolver<Void>
    ) {
        self.database = database
        self.logger = logger
        self.permission = permission
    }

    func execute(_ sourceURL: String) async throws -> Image? {
        _ = try await permission.grant()

        return try await Image.query(on: database)
            .filter(\.$sourceURL == sourceURL)
            .first()
    }
}

extension CommandFactory<String, Image?> {

    static var lookupImage: Self {
        CommandFactory { request in
            ImageLookupCommand(
                database: request.commandDB,
                logger: request.application.logger,
                permission: request.permissions.gallery.lookup
            )
            .logged(logger: request.logger)
        }
    }
}
