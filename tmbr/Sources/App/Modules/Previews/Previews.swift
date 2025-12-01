import Vapor
import Fluent
import Core

struct Previews: Module {
    
    func configure(_ app: Application) async throws {
        app.migrations.add(CreatePreview())
        app.migrations.add(AddPreviewParentAccessAndOwner())
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {}
}

extension Module where Self == Previews {
    
    static var previews: Self { Previews() }
}
