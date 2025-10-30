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
    
    func scope<S: PermissionScope>(_ type: S.Type) throws(PermissionError) -> S {
        guard let scope = scopes[String(describing: type)] as? S else {
            throw .missingPermission
        }
        return scope
    }
}

extension Application {
    public var permissions: PermissionService {
        get throws(PermissionError) {
            guard let service = storage[PermissionService.Key.self] else {
                throw .missingPermission
            }
            return service
        }
    }
}
