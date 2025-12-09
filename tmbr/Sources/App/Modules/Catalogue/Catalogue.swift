import Vapor
import Fluent
import Core
import AuthKit

struct Catalogue: Module {
    
    private let commands: CommandCollection
    
    private let media: ModuleRegistry
    
    init(
        commands: CommandCollection,
        media: ModuleRegistry
    ) {
        self.commands = commands
        self.media = media
    }

    func configure(_ app: Vapor.Application) async throws {
        try await app.commands.add(collection: commands)
        try await media.configure(app)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try await media.boot(routes)
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self {
        Catalogue(
            commands: Commands.Catalogue(),
            media: ModuleRegistry(
                configurations: [],
                modules: [
                    .books,
                    .movies,
                    .podcasts,
                    .songs,
                ]
            )
        )
    }
}
