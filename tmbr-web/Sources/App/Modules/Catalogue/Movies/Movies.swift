import Vapor
import Fluent
import WebCore
import WebAuth

struct Movies: Module {
    
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
        app.migrations.add(CreateMovie())
        app.migrations.add(AlterMovieReleaseDate())
        app.databases.middleware.use(PreviewModelMiddleware.movie, on: .psql)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: MoviesAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: MoviesWebController())
    }
}

extension Module where Self == Movies {
    static var movies: Self {
        Movies(
            commands: Commands.Movies(),
            permissions: PreviewablePermissionScope.movies
        )
    }
}
