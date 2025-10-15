import Fluent
import Vapor
import Core

struct Posts: Module {
    
    func configure(_ app: Vapor.Application) async throws {}
    
    func boot(_ app: Vapor.Application) async throws {
        try app.register(collection: PostsAPIController())
        try app.register(collection: PostsWebController())
    }
}

extension Module where Self == Posts {
    static var posts: Self {
        Posts()
    }
}
