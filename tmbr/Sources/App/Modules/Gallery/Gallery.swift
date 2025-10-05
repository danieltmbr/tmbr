import Vapor
import Fluent
import Core

struct Gallery: Module {
    fileprivate struct ServiceKey: StorageKey {
        typealias Value = ImageService
    }

    func configure(_ app: Vapor.Application) async throws {
        app.databases.middleware.use(
            ImageCleanupMiddleware(publicDirectory: app.directory.publicDirectory),
            on: .psql
        )
        app.storage[ServiceKey.self] = ImageService(publicDirectory: app.directory.publicDirectory)
        app.migrations.add(CreateImage())
    }
    
    func boot(_ app: Vapor.Application) async throws {
        try app.register(collection: GalleryAPIController())
    }
}

extension Module where Self == Gallery {
    static var gallery: Self { Gallery() }
}

extension Application {
    var imageService: ImageService? {
        storage[Gallery.ServiceKey.self]
    }
}
