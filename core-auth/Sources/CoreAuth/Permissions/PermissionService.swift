import Foundation
import Vapor

public actor PermissionService {
    
    public struct Key: StorageKey {
        public typealias Value = PermissionService
    }
    
    private var scopes: [String: PermissionScope] = [:]
    
    public init() {}
    
    public func add(scope: PermissionScope) {
        scopes[String(reflecting: type(of: scope))] = scope
    }
    
    func scope<S: PermissionScope>(_ type: S.Type) throws -> S {
        guard let scope = scopes[String(reflecting: type)] as? S else {
            throw Abort(.serviceUnavailable, reason: "Permission Scope (\(type)) is unavailable.")
        }
        return scope
    }
}

extension Application {
    public var permissions: PermissionService {
        get throws {
            guard let service = storage[PermissionService.Key.self] else {
                throw Abort(.serviceUnavailable, reason: "Permission Service is unavailable.")
            }
            return service
        }
    }
}
