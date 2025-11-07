import Foundation
import Vapor

public struct Permission<Input>: Sendable {
    
    @dynamicMemberLookup
    public struct AuthenticatedUser: Sendable {
        public let user: User
        
        public let userID: User.IDValue
        
        init(user: User, userID: User.IDValue) {
            self.user = user
            self.userID = userID
        }
        
        public subscript<V>(dynamicMember keyPath: KeyPath<User, V>) -> V {
            user[keyPath: keyPath]
        }
    }
        
    public typealias Grant = @Sendable (Request, Input) throws -> AuthenticatedUser
    
    private let grant: Grant
    
    public init(grant: @escaping Grant) {
        self.grant = grant
    }
    
    public init(
        verify: @Sendable @escaping (AuthenticatedUser, Input) throws -> Void
    ) {
        self.init { (request, input) in
            guard let user = request.auth.get(User.self),
                  let userID = user.id else {
                throw Abort(.unauthorized)
            }
            let authenticatedUser = AuthenticatedUser(user: user, userID: userID)
            try verify(authenticatedUser, input)
            return authenticatedUser
        }
    }
    
    /// Can be used for permission check where the
    /// only requirement is to have an authenticated user.
    /// 
    public init() where Input == Void {
        self.init { _, _ in }
    }
    
    public init(
        _ deniedReason: String,
        granted: @Sendable @escaping (AuthenticatedUser, Input) -> Bool
    ) {
        self.init { (user, input) in
            if !granted(user, input) {
                throw Abort(.forbidden, reason: deniedReason)
            }
        }
    }
    
    @discardableResult
    public func grant(_ input: Input, on request: Request) throws -> AuthenticatedUser {
        try self.grant(request, input)
    }
    
    @discardableResult
    public func grant(on request: Request) throws -> AuthenticatedUser
    where Input == Void {
        try self.grant((), on: request)
    }
}
