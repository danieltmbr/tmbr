import Foundation
import Vapor

protocol Permission<Input>: Sendable {
    
    associatedtype Input
    
    func verify(
        _ input: Input,
        for user: User
    ) -> Bool
}

extension Permission<Void> {
    func verify(_ user: User) -> Bool {
        self.verify((), for: user)
    }
}

protocol PermissionScope {}

struct PermissionScopes {
    
    struct PostPermissions: PermissionScope, Sendable {
        
        struct Create: Permission {
            func verify(_ input: Void, for user: User) -> Bool {
                user.role == .admin || user.role == .author
            }
        }
        
        struct Edit: Permission {
            func verify(_ post: Post, for user: User) -> Bool {
                user.role == .admin || post.author.id == user.id
            }
        }
        
        let create: Create
        
        let edit: Edit
    }

    var post: PostPermissions.Type { PostPermissions.self }
}

@dynamicMemberLookup
struct PermissionResolver<T> {
    
    let user: User
    
    let path: KeyPath<PermissionScopes, T>
    
    init(user: User, path: KeyPath<PermissionScopes, T>) {
        self.user = user
        self.path = path
    }
    
    subscript <U>(dynamicMember keyPath: KeyPath<T, U>) -> PermissionResolver<U> {
        PermissionResolver<U>(user: user, path: path.appending(path: keyPath))
    }
    
    func callAsFunction(_ input: T.Input) -> Bool
    where T: Permission {
        
    }
}

enum PermissionDynamicLookup {}

extension Request {

    var permissions: PermissionResolver<PermissionScopes> {
        
        PermissionResolver(user: self, path: \.self)
    }

    func valami() {
        
    }
}

extension PermissionDynamicLookup {
    subscript<Input>(
        dynamicMember keyPath: KeyPath<PermissionScopes.PostPermissions, any Permission<Input>>
    ) -> any Permission<Input> {
        
    }
}


