import Foundation
import Vapor

public protocol PermissionScope {}

@dynamicMemberLookup
public struct PermissionDynamicLookup<T>: Sendable {
        
    private let request: Request

    init(request: Request) {
        self.request = request
    }
    
    public subscript <S>(dynamicMember keyPath: KeyPath<T, S.Type>) -> PermissionDynamicLookup<S> {
        PermissionDynamicLookup<S>(request: request)
    }
    
    public subscript <Input>(
        dynamicMember keyPath: KeyPath<T, Permission<Input>>
    ) -> PermissionResolver<Input, Permission<Input>.AuthenticatedUser?>
    where T: PermissionScope {
        PermissionResolver(
            request: request,
            scope: T.self,
            keyPath: keyPath
        )
    }
    
    public subscript <Input>(
        dynamicMember keyPath: KeyPath<T, AuthenticatingPermission<Input>>
    ) -> PermissionResolver<Input, AuthenticatingPermission<Input>.AuthenticatedUser>
    where T: PermissionScope {
        PermissionResolver(
            request: request,
            scope: T.self,
            keyPath: keyPath
        )
    }
}
