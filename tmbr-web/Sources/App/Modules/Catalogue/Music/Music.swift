import Vapor
import WebCore

struct Music: Module {

    private let commands: CommandCollection

    init(commands: CommandCollection) {
        self.commands = commands
    }

    func configure(_ app: Vapor.Application) async throws {
        try await app.commands.add(collection: commands)
    }

    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: MusicAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: MusicWebController())
    }
}

extension Module where Self == Music {
    static var music: Self {
        Music(commands: Commands.Music())
    }
}
