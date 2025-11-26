import Vapor
import Fluent
import Core
import SotoCore

struct Catalogue: Module {

    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateMedia())
        app.migrations.add(CreateMediaNotes())
        app.migrations.add(CreateMediaItems())
        app.migrations.add(CreateMediaResource())
        app.migrations.add(AddMediaIDToPosts())
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self { Catalogue() }
}
