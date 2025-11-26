import AuthKit
import Fluent
import Vapor
import Core

struct Previews: Configuration {
        
    private let commands: Commands.Previews
    
    init(commands: Commands.Previews) {
        self.commands = commands
    }
    
    func configure(_ app: Vapor.Application) async throws {
        await app.storage.setWithAsyncShutdown(
            PreviewService.Key.self,
            to: PreviewService()
        )
        try await app.commands.add(collection: commands)
    }
}

extension Configuration where Self == Previews {
    static var previews: Self {
        Previews(commands: Commands.Previews())
    }
}
