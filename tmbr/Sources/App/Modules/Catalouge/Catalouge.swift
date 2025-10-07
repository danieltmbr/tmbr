import Vapor
import Fluent
import Core
import SotoCore

struct Catalouge: Module {
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateMedia())
        app.migrations.add(CreateMediaNotes())
        app.migrations.add(AddMediaIDToPosts())
        app.migrations.add(CreateBooks())
        app.migrations.add(CreateMovies())
        app.migrations.add(CreateMusic())
        app.migrations.add(CreatePodcasts())
        app.migrations.add(CreateMediaResources())
    }
    
    func boot(_ app: Vapor.Application) async throws {
    }
}

extension Module where Self == Catalouge {
    static var catalouge: Self { Catalouge() }
}
