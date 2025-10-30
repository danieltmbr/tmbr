import Foundation

public actor PermissionService {
    
    private var scopes: [String: PermissionScope] = [:]
    
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
