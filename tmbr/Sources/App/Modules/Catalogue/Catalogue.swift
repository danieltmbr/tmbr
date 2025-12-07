import Vapor
import Fluent
import Core
import AuthKit

struct Catalogue: Module {
    
    private let permissions: [PermissionScope]
    
    private let commands: [CommandCollection]
    
    init(
        bookCommands: CommandCollection,
        bookPermissions: PermissionScope,
        movieCommands: CommandCollection,
        moviePermissions: PermissionScope,
        podcastCommands: CommandCollection,
        podcastPermissions: PermissionScope,
        songPermissions: PermissionScope,
        catalogueCommands: CommandCollection
    ) {
        self.permissions = [
            bookPermissions,
            moviePermissions,
            podcastPermissions,
            songPermissions
        ]
        self.commands = [
            catalogueCommands,
            bookCommands,
            movieCommands,
            podcastCommands,
        ]
    }

    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateBook())
        app.migrations.add(CreateBookNote())
        
        app.migrations.add(CreateMovie())
        app.migrations.add(CreateMovieNote())
        
        app.migrations.add(CreatePodcast())
        app.migrations.add(CreatePodcastNote())
        
        app.migrations.add(CreateSong())
        app.migrations.add(CreateSongNote())

        app.databases.middleware.use(PreviewModelMiddleware.book, on: .psql)
        app.databases.middleware.use(PreviewModelMiddleware.movie, on: .psql)
        app.databases.middleware.use(PreviewModelMiddleware.podcast, on: .psql)
        app.databases.middleware.use(PreviewModelMiddleware.song, on: .psql)
        
        for scope in permissions {
            try await app.permissions.add(scope: scope)
        }
        for collection in commands {
            try await app.commands.add(collection: collection)
        }
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self {
        Catalogue(
            bookCommands: Commands.Books(),
            bookPermissions: PreviewablePermissionScope.books,
            movieCommands: Commands.Movies(),
            moviePermissions: PreviewablePermissionScope.movies,
            podcastCommands: Commands.Podcasts(),
            podcastPermissions: PreviewablePermissionScope.podcasts,
            songPermissions: PreviewablePermissionScope.songs,
            catalogueCommands: Commands.Catalogue()
        )
    }
}
