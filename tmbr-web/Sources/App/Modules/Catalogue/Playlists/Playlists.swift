import Vapor
import Fluent
import WebCore
import WebAuth

struct Playlists: Module {

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
        app.migrations.add(CreatePlaylist())
        app.migrations.add(DeferPlaylistPreviewForeignKey())
        app.migrations.add(AddCreatedAtToPlaylist())
        app.databases.middleware.use(PreviewModelMiddleware.playlist, on: .psql)

        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }

    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: PlaylistsAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: PlaylistsWebController())
    }
}

extension Module where Self == Playlists {
    static var playlists: Self {
        Playlists(
            commands: Commands.Playlists(),
            permissions: PreviewablePermissionScope.playlists
        )
    }
}
