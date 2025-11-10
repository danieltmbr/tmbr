import AuthKit
import Fluent
import Vapor
import Core

struct Posts: Module {
    
    private let permissions: PermissionScopes.Posts
    
    private let commands: Commands.Posts
    
    init(
        permissions: PermissionScopes.Posts,
        commands: Commands.Posts
    ) {
        self.permissions = permissions
        self.commands = commands
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreatePost())
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: PostsAPIController())
        try routes.register(collection: PostsWebController())
    }
}

extension Module where Self == Posts {
    static var posts: Self {
        Posts(
            permissions: PermissionScopes.Posts(),
            commands: Commands.Posts()
        )
    }
}
