import Foundation
import Vapor

private struct PermissionServiceKey: StorageKey {
    typealias Value = PermissionService
}

extension Configuration where Self == CoreConfiguration {
    public static var permissions: Self {
        CoreConfiguration { app in
            await app.storage.setWithAsyncShutdown(
                PermissionServiceKey.self,
                to: PermissionService()
            )
        }
    }
}

extension Application {
    public var permissions: PermissionService {
        get throws(PermissionError) {
            guard let service = storage[PermissionServiceKey.self] else {
                throw .missingPermission
            }
            return service
        }
    }
}
