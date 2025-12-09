import Vapor
import Fluent
import Core
import AuthKit

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
        app.migrations.add(CreateSongNote())
        app.databases.middleware.use(PreviewModelMiddleware.song, on: .psql)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
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
