import Vapor
import Fluent
import Core
import SotoCore
import AuthKit

struct Gallery: Module {
    fileprivate struct ServiceKey: StorageKey {
        typealias Value = ImageService
    }
    
    private let commands: Commands.Gallery
    
    private let permissions: PermissionScopes.Gallery
    
    init(
        commands: Commands.Gallery,
        permissions: PermissionScopes.Gallery
    ) {
        self.commands = commands
        self.permissions = permissions
    }

    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateImage())

        let storage: FileStorage
        if app.environment == .production {
            storage = S3FileStorage(
                bucket: Environment.gallery.bucket ,
                region: Region(rawValue: Environment.gallery.region)
            )
        } else {
            storage = InMemoryFileStorage()
        }
        app.storage[ServiceKey.self] = DefaultImageService(storage: storage)
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: GalleryAPIController())
        try routes.register(collection: GalleryWebController())
    }
}

extension Module where Self == Gallery {
    static var gallery: Self {
        Gallery(
            commands: Commands.Gallery(),
            permissions: PermissionScopes.Gallery()
        )
    }
}

extension Application {
    var imageService: ImageService? {
        storage[Gallery.ServiceKey.self]
    }
}
