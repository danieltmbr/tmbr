import Foundation
import Vapor

public struct Permission<Input>: Sendable {
    
    @dynamicMemberLookup
    public struct User: Sendable {
        public let user: AuthKit.User
        
        public let userID: UserID
        
        public init(user: AuthKit.User, userID: UserID) {
            self.user = user
            self.userID = userID
        }
        
        public init?(user: AuthKit.User?, userID: UserID?) {
            guard let user, let userID else { return nil }
            self.init(user: user, userID: userID)
        }
        
        public subscript<V>(dynamicMember keyPath: KeyPath<AuthKit.User, V>) -> V {
            user[keyPath: keyPath]
        }
    }
        
    public typealias Grant = @Sendable (Request, Input) throws -> User?
    
    private let grant: Grant
    
    public init(grant: @escaping Grant) {
        self.grant = grant
    }
    
    public init(
        grant: @Sendable @escaping (User?, Input) throws -> Void
    ) {
        self.init { (request, input) in
            let user = request.auth.get(AuthKit.User.self)
            let authenticatedUser = User(user: user, userID: user?.id)
            try grant(authenticatedUser, input)
            return authenticatedUser
        }
    }
    
    public init(
        _ deniedReason: String,
        granted: @Sendable @escaping (User?, Input) throws -> Bool
    ) {
        self.init { (user, input) in
            if try !granted(user, input) {
                throw Abort(.forbidden, reason: deniedReason)
            }
        }
    }
    
    @discardableResult
    public func grant(_ input: Input, on request: Request) throws -> User? {
        try self.grant(request, input)
    }
    
    @discardableResult
    public func grant(on request: Request) throws -> User?
    where Input == Void {
        try self.grant((), on: request)
    }
}
