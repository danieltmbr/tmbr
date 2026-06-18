import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<Void, [Image]> {
    
    // TODO: Maybe filter by logged in owner
    static func listImages(
        database: Database,
        permission: AuthPermissionResolver<Void>
    ) -> Self {
        PlainCommand {
            try await permission.grant()
            return try await Image.query(on: database)
                .sort(\.$uploadedAt, .descending)
                .all()
        }
    }
}

extension CommandFactory<Void, [Image]> {
    
    static var listImages: Self {
        CommandFactory { request in
            .listImages(
                database: request.commandDB,
                permission: request.permissions.gallery.list
            )
            .logged(name: "List images", logger: request.logger)
        }
    }
}
