import Vapor
import Fluent
import Core
import AuthKit

struct Catalogue: Module {
    
    private let permissions: [PermissionScope]
    
    init(
        bookPermissions: PermissionScope,
        moviePermissions: PermissionScope,
        podcastPermissions: PermissionScope,
        songPermissions: PermissionScope
    ) {
        self.permissions = [
            bookPermissions,
            moviePermissions,
            podcastPermissions,
            songPermissions
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
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self {
        Catalogue(
            bookPermissions: PreviewablePermissionScope.books,
            moviePermissions: PreviewablePermissionScope.movies,
            podcastPermissions: PreviewablePermissionScope.podcasts,
            songPermissions: PreviewablePermissionScope.songs
        )
    }
}
