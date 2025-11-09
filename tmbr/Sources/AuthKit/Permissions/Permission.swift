import Foundation
import Vapor

public struct Permission<Input>: Sendable {
    
    @dynamicMemberLookup
    public struct AuthenticatedUser: Sendable {
        public let user: User
        
        public let userID: User.IDValue
        
        public init(user: User, userID: User.IDValue) {
            self.user = user
            self.userID = userID
        }
        
        public init?(user: User?, userID: User.IDValue?) {
            guard let user, let userID else { return nil }
            self.init(user: user, userID: userID)
        }
        
        public subscript<V>(dynamicMember keyPath: KeyPath<User, V>) -> V {
            user[keyPath: keyPath]
        }
    }
        
    public typealias Grant = @Sendable (Request, Input) throws -> AuthenticatedUser?
    
    private let grant: Grant
    
    public init(grant: @escaping Grant) {
        self.grant = grant
    }
    
    public init(
        grant: @Sendable @escaping (AuthenticatedUser?, Input) throws -> Void
    ) {
        self.init { (request, input) in
            let user = request.auth.get(User.self)
            let authenticatedUser = AuthenticatedUser(user: user, userID: user?.id)
            try grant(authenticatedUser, input)
            return authenticatedUser
        }
    }
    
    public init(
        _ deniedReason: String,
        granted: @Sendable @escaping (AuthenticatedUser?, Input) throws -> Bool
    ) {
        self.init { (user, input) in
            if try !granted(user, input) {
                throw Abort(.forbidden, reason: deniedReason)
            }
        }
    }
    
    @discardableResult
    public func grant(_ input: Input, on request: Request) throws -> AuthenticatedUser? {
        try self.grant(request, input)
    }
    
    @discardableResult
    public func grant(on request: Request) throws -> AuthenticatedUser?
    where Input == Void {
        try self.grant((), on: request)
    }
}
