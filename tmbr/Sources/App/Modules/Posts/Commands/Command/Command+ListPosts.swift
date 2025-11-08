import Foundation
import Vapor
import Core
import Logging
import Fluent

extension Core.Command where Self == PlainCommand<Void, [Post]> {
    
    static func listPosts(
        database: Database,
        logger: Logger
    ) -> Self {
        PlainCommand {
            try await Post.query(on: database)
                .filter(\.$state == .published)
                .with(\.$author)
                .all()
        }
    }
}

extension CommandFactory<Void, [Post]> {
    
    static var listPosts: Self {
        CommandFactory { request in
            .listPosts(
                database: request.db,
                logger: request.logger
            )
            .logged(
                name: "List posts",
                logger: request.logger
            )
        }
    }
}
