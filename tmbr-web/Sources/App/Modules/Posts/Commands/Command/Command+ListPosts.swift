import Foundation
import Vapor
import Core
import Logging
import Fluent

extension Command where Self == PlainCommand<Void, [Post]> {
    
    static func listPosts(database: Database) -> Self {
        PlainCommand {
            try await Post.query(on: database)
                .filter(\.$state == .published)
                .sort(\.$createdAt, .descending)
                .with(\.$author)
                .all()
        }
    }
}

extension CommandFactory<Void, [Post]> {
    
    static var listPosts: Self {
        CommandFactory { request in
            .listPosts(database: request.commandDB)
            .logged(
                name: "List posts",
                logger: request.logger
            )
        }
    }
}
