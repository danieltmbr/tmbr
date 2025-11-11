import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<Void, [Image]> {
    
    // TODO: Maybe filter by logged in owner
    static func listPosts(
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
            .listPosts(
                database: request.db,
                permission: request.permissions.gallery.list
            )
            .logged(name: "List images", logger: request.logger)
        }
    }
}
