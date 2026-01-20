import Vapor
import Fluent
import Core
import AuthKit

struct Podcasts: Module {
    
    private let commands: CommandCollection
    
    private let permissions: PermissionScope
    
    init(
        commands: CommandCollection,
        permissions: PermissionScope
    ) {
        self.commands = commands
        self.permissions = permissions
    }

    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreatePodcast())
        app.databases.middleware.use(PreviewModelMiddleware.podcast, on: .psql)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Podcasts {
    static var podcasts: Self {
        Podcasts(
            commands: Commands.Podcasts(),
            permissions: PreviewablePermissionScope.podcasts
        )
    }
}
