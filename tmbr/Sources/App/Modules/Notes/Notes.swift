import Vapor
import Fluent
import Core
import SotoCore

struct Notes: Module {
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateNote())
        app.migrations.add(CreateQuote())
        app.databases.middleware.use(NoteModelMiddleware())
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
    }
}

extension Module where Self == Notes {
    static var notes: Self { Notes() }
}
