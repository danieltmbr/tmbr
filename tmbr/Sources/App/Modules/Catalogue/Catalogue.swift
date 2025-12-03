import Vapor
import Fluent
import Core
import SotoCore

struct Catalogue: Module {

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
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self { Catalogue() }
}
