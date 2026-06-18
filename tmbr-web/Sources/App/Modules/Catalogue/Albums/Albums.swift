import Vapor
import Fluent
import CoreWeb
import CoreAuth

struct Albums: Module {

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
        app.migrations.add(CreateAlbum())
        app.migrations.add(DeferAlbumPreviewForeignKey())
        app.databases.middleware.use(PreviewModelMiddleware.album, on: .psql)

        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }

    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: AlbumsAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: AlbumsWebController())
    }
}

extension Module where Self == Albums {
    static var albums: Self {
        Albums(
            commands: Commands.Albums(),
            permissions: PreviewablePermissionScope.albums
        )
    }
}
