import Vapor
import Fluent
import Core
import AuthKit

struct Catalogue: Module {
        
    private let media: ModuleRegistry
    
    init(
        media: ModuleRegistry
    ) {
        self.media = media
    }

    func configure(_ app: Vapor.Application) async throws {
        try await media.configure(app)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try await media.boot(routes)
    }
}

extension Module where Self == Catalogue {
    static var catalogue: Self {
        Catalogue(
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
