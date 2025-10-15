import Vapor
import Fluent
import Core
import SotoCore

struct Catalouge: Module {
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateMedia())
        app.migrations.add(CreateMediaNotes())
        app.migrations.add(CreateMediaItems())
        app.migrations.add(CreateMediaResource())
        app.migrations.add(AddMediaIDToPosts())
    }
    
    func boot(_ app: Vapor.Application) async throws {
    }
}

extension Module where Self == Catalouge {
    static var catalouge: Self { Catalouge() }
}
