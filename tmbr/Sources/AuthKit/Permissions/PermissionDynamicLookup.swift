import Foundation
import Vapor

@dynamicMemberLookup
public struct PermissionDynamicLookup<T> {
    
    private let path: KeyPath<PermissionScopes, T>
    
    private let request: Request

    init(request: Request, path: KeyPath<PermissionScopes, T>) {
        self.request = request
        self.path = path
    }
    
    public subscript <U>(dynamicMember keyPath: KeyPath<T, U>) -> PermissionDynamicLookup<U> {
        PermissionDynamicLookup<U>(request: request, path: path.appending(path: keyPath))
    }
    
    public subscript <Scope, Input>(dynamicMember keyPath: KeyPath<Scope, Permission<Input>>) -> PermissionResolver<Input>
    where Scope: PermissionScope, Scope.Type == T {
        get async throws {
            let permissions = try request.application.permissions
            let scope = try await permissions.scope(Scope.self)
            let permission = scope[keyPath: keyPath]
            return PermissionResolver(request: request, permission: permission)
        }
    }
}

extension Request {
    public var permissions: PermissionDynamicLookup<PermissionScopes> {
        PermissionDynamicLookup(request: self, path: \.self)
    }
}
