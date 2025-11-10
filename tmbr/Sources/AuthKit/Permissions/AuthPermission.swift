import Foundation
import Vapor

public struct AuthPermission<Input>: Sendable {
    
    public typealias User = Permission<Input>.User
    
    public typealias Grant = @Sendable (Request, Input) throws -> User
    
    private let grant: Grant
    
    public init(grant: @escaping Grant) {
        self.grant = grant
    }
    
    public init(
        grant: @Sendable @escaping (User, Input) throws -> Void
    ) {
        self.init { (request, input) in
            guard let user = request.auth.get(AuthKit.User.self),
                  let userID = user.id else {
                throw Abort(.unauthorized)
            }
            let authenticatedUser = User(user: user, userID: userID)
            try grant(authenticatedUser, input)
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
        granted: @Sendable @escaping (User, Input) -> Bool
    ) {
        self.init { (user, input) in
            if !granted(user, input) {
                throw Abort(.forbidden, reason: deniedReason)
            }
        }
    }
    
    @discardableResult
    public func grant(_ input: Input, on request: Request) throws -> User {
        try self.grant(request, input)
    }
    
    @discardableResult
    public func grant(on request: Request) throws -> User
    where Input == Void {
        try self.grant((), on: request)
    }
}
