import Vapor
import Fluent
import Core
import SotoCore

struct Gallery: Module {
    fileprivate struct ServiceKey: StorageKey {
        typealias Value = ImageService
    }

    func configure(_ app: Vapor.Application) async throws {
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
    }
    
    func boot(_ app: Vapor.Application) async throws {
        try app.register(collection: GalleryAPIController())
        try app.register(collection: GalleryWebController())
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
