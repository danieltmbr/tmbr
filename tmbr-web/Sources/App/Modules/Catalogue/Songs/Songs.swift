import Vapor
import Fluent
import WebCore
import WebAuth

struct Songs: Module {
    
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
        app.migrations.add(CreateSong())
        app.databases.middleware.use(PreviewModelMiddleware.song, on: .psql)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: SongsAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: SongsWebController())
    }
}

extension Module where Self == Songs {
    static var songs: Self {
        Songs(
            commands: Commands.Songs(),
            permissions: PreviewablePermissionScope.songs
        )
    }
}
